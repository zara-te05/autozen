import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'notificaciones_service.dart';
import 'sesion.dart';

/// Aviso de un evento del taller (proyecto nuevo, compra solicitada o aprobada, etc.).
class Aviso {
  final int id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final DateTime fecha;

  const Aviso({required this.id, required this.tipo, required this.titulo, required this.mensaje, required this.fecha});

  factory Aviso.fromJson(Map<String, dynamic> j) => Aviso(
        id: (j['id'] as num).toInt(),
        tipo: j['tipo'] as String? ?? '',
        titulo: j['titulo'] as String? ?? '',
        mensaje: j['mensaje'] as String? ?? '',
        fecha: DateTime.parse(j['fecha'] as String),
      );
}

/// Bandeja de avisos (la campanita del menú).
///
/// Esquema híbrido para no cargar al backend:
/// - Los **eventos** (proyecto nuevo o editado, compra solicitada o aprobada) los registra el backend
///   para los roles que corresponden; la app los consulta al iniciar sesión, al volver a abrirla
///   y cada 5 minutos mientras está abierta, con un solo GET que solo trae lo nuevo.
/// - Lo que se puede **calcular** con los datos que la app ya tiene (stock bajo, retrasos, entregas,
///   herramientas sin devolver) lo calcula el teléfono: ver [NotificacionesService].
class AvisosStore extends ChangeNotifier {
  AvisosStore._();

  static final AvisosStore instancia = AvisosStore._();

  static const String _claveLeidos = 'avisos_leidos_hasta';
  static const String _claveMostrados = 'avisos_mostrados_hasta';

  final ApiClient _api = ApiClient();
  final List<Aviso> _avisos = [];
  int _leidosHasta = 0;
  int _idLocal = 1000000;
  Timer? _sondeo;

  List<Aviso> get avisos => List.unmodifiable(_avisos);
  int get noLeidos => _avisos.where((a) => a.id > _leidosHasta).length;
  bool esNuevo(Aviso a) => a.id > _leidosHasta;

  /// Modo demo: el evento se registra en el propio dispositivo si el rol actual debe recibirlo.
  /// Con sesión real no hace nada: el backend genera el evento.
  void registrarLocal({required String tipo, required String titulo, required String mensaje, required List<String> roles}) {
    if (!Sesion.modoDemo || !roles.contains(Sesion.rol)) return;
    final aviso = Aviso(id: ++_idLocal, tipo: tipo, titulo: titulo, mensaje: mensaje, fecha: DateTime.now());
    _avisos.insert(0, aviso);
    notifyListeners();
    NotificacionesService.instancia.mostrarAviso(aviso);
  }

  /// Trae los avisos del backend para el rol del usuario y muestra en el teléfono los que no se habían mostrado.
  Future<String?> cargar() async {
    if (Sesion.modoDemo) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      _leidosHasta = prefs.getInt(_claveLeidos) ?? 0;
      final mostradosHasta = prefs.getInt(_claveMostrados) ?? 0;

      final datos = await _api.get('/Notificacion') as List;
      _avisos
        ..clear()
        ..addAll(datos.map((j) => Aviso.fromJson(Map<String, dynamic>.from(j as Map))));
      notifyListeners();

      final nuevos = _avisos.where((a) => a.id > mostradosHasta).toList();
      if (nuevos.isNotEmpty) {
        // La primera vez solo se marcan; no se inunda el teléfono con el historial
        if (mostradosHasta > 0) await NotificacionesService.instancia.mostrarAvisos(nuevos);
        await prefs.setInt(_claveMostrados, nuevos.map((a) => a.id).reduce((a, b) => a > b ? a : b));
      }
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<void> marcarLeidos() async {
    if (_avisos.isEmpty) return;
    _leidosHasta = _avisos.map((a) => a.id).reduce((a, b) => a > b ? a : b);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_claveLeidos, _leidosHasta);
    } catch (_) {}
  }

  void iniciarSondeo() {
    _sondeo?.cancel();
    _sondeo = Timer.periodic(const Duration(minutes: 5), (_) => cargar());
  }

  void reiniciarDemo() {
    _sondeo?.cancel();
    _sondeo = null;
    _avisos.clear();
    _leidosHasta = 0;
    notifyListeners();
  }
}
