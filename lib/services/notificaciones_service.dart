import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../models/almacen_inventario.dart';
import '../models/proyecto_taller.dart';
import '../utils/formato_fecha.dart';
import 'almacen_store.dart';
import 'avisos_store.dart';
import 'proyectos_store.dart';
import 'sesion.dart';

/// Notificaciones locales del teléfono (Android/iOS; en Windows no hace nada).
///
/// Parte "calculada" del esquema híbrido: se obtiene de los datos que la app ya tiene, sin pedir nada extra
/// al backend, y cada rol recibe solo lo suyo:
///
/// | Aviso                                   | Admin | Proyectos | Almacén |
/// |-----------------------------------------|:-----:|:---------:|:-------:|
/// | Stock bajo o agotado                    |   ✓   |           |    ✓    |
/// | Entregas próximas (programadas)         |   ✓   |           |         |
/// | Proyectos con etapa atrasada            |   ✓   |           |         |
/// | Herramientas por devolver               |       |     ✓     |    ✓    |
///
/// Los eventos (proyecto nuevo/editado, compra solicitada/aprobada) llegan del backend: ver AvisosStore.
class NotificacionesService {
  NotificacionesService._();

  static final NotificacionesService instancia = NotificacionesService._();

  static const int _idStock = 1;
  static const int _idHerramientas = 2;
  static const int _idEtapas = 3;
  static const int _baseEntregaHoy = 1000;
  static const int _baseProgramadas = 100000;
  static const int _baseAvisos = 200000;
  static const String _clavesStock = 'notif_stock_avisado';
  static const String _clavesProgramadas = 'notif_programadas';

  static const NotificationDetails _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'alertas_taller',
      'Alertas del taller',
      channelDescription: 'Stock bajo, entregas próximas y recordatorios',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _listo = false;
  Timer? _espera;

  static bool _rol(List<String> roles) => roles.contains(Sesion.rol);

  static bool get _soportado => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> iniciar() async {
    if (!_soportado || _listo) return;
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _listo = true;
      ProyectosStore.instancia.addListener(_programarEvaluacion);
      AlmacenStore.instancia.addListener(_programarEvaluacion);
      _programarEvaluacion();
    } catch (e) {
      debugPrint('No se pudieron iniciar las notificaciones: $e');
    }
  }

  /// Agrupa varios cambios seguidos en una sola evaluación.
  void _programarEvaluacion() {
    _espera?.cancel();
    _espera = Timer(const Duration(seconds: 2), () => evaluar());
  }

  Future<void> evaluar() async {
    if (!_listo) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await _avisarStockBajo(prefs);
      await _programarEntregas(prefs);
      await _recordatoriosDelDia(prefs);
    } catch (e) {
      debugPrint('Error al evaluar notificaciones: $e');
    }
  }

  // ------------------------------------------------------------------ Stock bajo

  Future<void> _avisarStockBajo(SharedPreferences prefs) async {
    if (!_rol(const ['Admin', 'Almacen_Admin'])) return;
    final bajos = AlmacenStore.instancia.articulos
        .where((a) => a.tipo == TipoArticulo.material && (a.agotado || a.bajoStock))
        .toList();
    final avisados = (prefs.getStringList(_clavesStock) ?? const []).toSet();
    final nuevos = bajos.where((a) => !avisados.contains(a.id)).toList();

    if (nuevos.length == 1) {
      final a = nuevos.first;
      await _mostrar(
        _idStock,
        a.agotado ? 'Agotado: ${a.nombre}' : 'Stock bajo: ${a.nombre}',
        a.agotado ? 'Ya no hay existencias en almacén.' : 'Quedan ${a.unidad.formatear(a.existencia)} en almacén.',
      );
    } else if (nuevos.length > 1) {
      await _mostrar(
        _idStock,
        '${nuevos.length} materiales con stock bajo',
        nuevos.take(4).map((a) => '${a.nombre} (${a.unidad.formatear(a.existencia)})').join(', '),
      );
    }
    // Los que se reabastecieron salen de la lista y volverán a avisar si bajan otra vez
    await prefs.setStringList(_clavesStock, bajos.map((a) => a.id).toList());
  }

  // ------------------------------------------------------------------ Entregas

  Future<void> _programarEntregas(SharedPreferences prefs) async {
    for (final id in prefs.getStringList(_clavesProgramadas) ?? const <String>[]) {
      final n = int.tryParse(id);
      if (n != null) await _plugin.cancel(id: n);
    }

    final ahora = DateTime.now();
    final programadas = <String>[];
    // Las fechas de entrega solo le llegan al administrador
    final pendientes = _rol(const ['Admin'])
        ? ProyectosStore.instancia.todos.where((p) => !p.archivado && !p.terminado)
        : const <ProyectoTaller>[];

    for (final p in pendientes) {
      final entrega = p.fechaEntrega;
      final dia = DateTime(entrega.year, entrega.month, entrega.day);
      final avisos = <(DateTime, String)>[
        if (p.esAseguradora) ...[
          (dia.subtract(const Duration(days: 2)).add(const Duration(hours: 9)), 'Faltan 2 días para entregar a ${p.nombreContraparte}'),
          (dia.subtract(const Duration(days: 1)).add(const Duration(hours: 9)), 'Mañana se entrega a ${p.nombreContraparte}'),
          (dia.add(const Duration(hours: 8)), 'HOY se entrega a ${p.nombreContraparte}. Si no, hay multa.'),
        ] else
          (dia.subtract(const Duration(days: 1)).add(const Duration(hours: 9)), 'Mañana es la entrega estimada a ${p.nombreContraparte}'),
      ];

      for (int k = 0; k < avisos.length; k++) {
        final (cuando, texto) = avisos[k];
        if (!cuando.isAfter(ahora)) continue;
        final id = _baseProgramadas + (_numero(p.id) * 10) + k;
        await _plugin.zonedSchedule(
          id: id,
          title: '${p.nombreCamion} (${p.placa})',
          body: texto,
          scheduledDate: tz.TZDateTime.from(cuando, tz.UTC),
          notificationDetails: _detalles,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
        programadas.add('$id');
      }

      // Si ya está dentro del plazo (o vencido), avisar una vez hoy
      if ((p.entregaProxima || (p.esAseguradora && p.entregaVencida))) {
        final clave = 'notif_entrega_${p.id}_${_hoy()}';
        if (prefs.getBool(clave) != true) {
          final dias = p.diasParaEntrega;
          await _mostrar(
            _baseEntregaHoy + _numero(p.id),
            '${p.nombreCamion} (${p.placa})',
            dias < 0
                ? 'La entrega a ${p.nombreContraparte} venció hace ${-dias} día(s).'
                : dias == 0
                    ? 'HOY se entrega a ${p.nombreContraparte}.'
                    : 'Faltan $dias día(s) para entregar a ${p.nombreContraparte} (${formatearFecha(p.fechaEntrega)}).',
          );
          await prefs.setBool(clave, true);
        }
      }
    }
    await prefs.setStringList(_clavesProgramadas, programadas);
  }

  // ------------------------------------------------------------------ Recordatorios automáticos

  Future<void> _recordatoriosDelDia(SharedPreferences prefs) async {
    final hoy = _hoy();

    // Herramientas prestadas hace más de un día
    final claveHerramientas = 'notif_herramientas_$hoy';
    if (_rol(const ['Proyecto_Lider', 'Almacen_Admin']) && prefs.getBool(claveHerramientas) != true) {
      final atrasadas = AlmacenStore.instancia.valesHerramienta
          .where((v) => !v.devuelto && DateTime.now().difference(v.fechaSalida).inHours >= 24)
          .toList();
      if (atrasadas.isNotEmpty) {
        await _mostrar(
          _idHerramientas,
          Sesion.rol == 'Proyecto_Lider'
              ? 'Se tienen que devolver ${atrasadas.length} herramienta(s)'
              : '${atrasadas.length} herramienta(s) no devueltas o pendientes',
          atrasadas.take(3).map((v) => '${v.articuloNombre} (${v.entregadoA})').join(', '),
        );
        await prefs.setBool(claveHerramientas, true);
      }
    }

    // Proyectos cuya etapa actual ya pasó sus días estimados
    final claveEtapas = 'notif_etapas_$hoy';
    if (_rol(const ['Admin']) && prefs.getBool(claveEtapas) != true) {
      final atrasados = ProyectosStore.instancia.todos.where((p) => !p.archivado && !p.terminado && _etapaAtrasada(p)).toList();
      if (atrasados.isNotEmpty) {
        await _mostrar(
          _idEtapas,
          '${atrasados.length} proyecto(s) con etapa atrasada',
          atrasados.take(3).map((p) => '${p.nombreCamion}: ${p.nombreEtapaActual}').join(' • '),
        );
        await prefs.setBool(claveEtapas, true);
      }
    }
  }

  /// La etapa en curso debió terminar antes de hoy según los días planeados.
  static bool _etapaAtrasada(ProyectoTaller p) {
    final diasHastaFinDeEtapa = p.etapas.take(p.etapaActual + 1).fold<int>(0, (s, e) => s + e.diasEstimados);
    final finEtapa = p.fechaIngreso.add(Duration(days: diasHastaFinDeEtapa));
    return ProyectoTaller.diasEntre(finEtapa, DateTime.now()) > 0;
  }

  // ------------------------------------------------------------------ Eventos (AvisosStore)

  Future<void> mostrarAviso(Aviso aviso) async {
    if (!_listo) return;
    await _mostrar(_baseAvisos + (aviso.id % 100000), aviso.titulo, aviso.mensaje);
  }

  Future<void> mostrarAvisos(List<Aviso> avisos) async {
    if (!_listo || avisos.isEmpty) return;
    if (avisos.length <= 3) {
      for (final a in avisos) {
        await mostrarAviso(a);
      }
    } else {
      await _mostrar(_baseAvisos, '${avisos.length} avisos nuevos', avisos.take(3).map((a) => a.titulo).join(' • '));
    }
  }

  // ------------------------------------------------------------------ Auxiliares

  Future<void> _mostrar(int id, String titulo, String cuerpo) =>
      _plugin.show(id: id, title: titulo, body: cuerpo, notificationDetails: _detalles);

  static String _hoy() {
    final d = DateTime.now();
    return '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  }

  /// Número estable a partir del código del proyecto (PC-012 → 12; PA-003 → 50003).
  static int _numero(String codigo) {
    final n = int.tryParse(codigo.split('-').last) ?? codigo.hashCode.abs() % 10000;
    return codigo.startsWith('PA') ? 50000 + (n % 50000) : n % 50000;
  }
}
