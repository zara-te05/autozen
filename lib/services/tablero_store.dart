import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/tablero.dart';
import 'api_client.dart';
import 'proyectos_store.dart';
import 'sesion.dart';

/// Tablero de inicio del dashboard:
/// 1. Entregas de unidades de la semana: salen de los proyectos existentes (fecha comprometida con la
///    aseguradora o, en proyectos de cliente, la estimada por etapas). El Admin puede agregar entregas
///    manuales o quitar proyectos del tablero.
/// 2. Coordinación operativa del día (post-its de cuadrillas que se borran a las 7 pm).
/// 3. Anuncios.
///
/// Todos lo ven; solo el Admin crea, edita y elimina. En modo demo vive en memoria.
class TableroStore extends ChangeNotifier {
  TableroStore._() {
    _cargarEjemplos();
    _programarCorte();
  }

  static final TableroStore instancia = TableroStore._();

  /// Hora en que se borra la coordinación del día.
  static const int horaCorte = 19;

  final ApiClient _api = ApiClient();
  final List<EntregaSemana> _entregas = [];

  /// Modo demo: proyectos que el Admin quitó del tablero (código → fecha de entrega al quitarlo).
  final Map<String, DateTime> _ocultosDemo = {};
  final List<NotaCoordinacion> _coordinacion = [];
  final List<Anuncio> _anuncios = [];
  int _idLocal = 1000;
  Timer? _timerCorte;
  bool _cargando = false;

  bool get cargando => _cargando;

  // ------------------------------------------------------------------
  // Fechas
  // ------------------------------------------------------------------

  /// Lunes de la semana actual.
  static DateTime get inicioSemana {
    final hoy = soloFecha(DateTime.now());
    return hoy.subtract(Duration(days: hoy.weekday - DateTime.monday));
  }

  static DateTime get finSemana => inicioSemana.add(const Duration(days: 6));

  /// Último corte de las 7 pm que ya pasó.
  static DateTime get ultimoCorte {
    final ahora = DateTime.now();
    final corteHoy = DateTime(ahora.year, ahora.month, ahora.day, horaCorte);
    return ahora.isBefore(corteHoy) ? corteHoy.subtract(const Duration(days: 1)) : corteHoy;
  }

  /// Siguiente corte de las 7 pm (cuándo se borrarán las notas actuales).
  static DateTime get siguienteCorte => ultimoCorte.add(const Duration(days: 1));

  // ------------------------------------------------------------------
  // Lectura
  // ------------------------------------------------------------------

  /// Entregas de esta semana (y proyectos atrasados sin terminar), ordenadas por día.
  /// Las ocultas solo las ve el Admin, al final.
  List<EntregaSemana> get entregas {
    final inicio = inicioSemana;
    final fin = finSemana;
    final lista = <EntregaSemana>[
      // Con sesión real el backend ya manda solo lo de esta semana (más los proyectos atrasados)
      ..._entregas.where((e) => !Sesion.modoDemo || e.esProyecto || (!e.fechaEntrega.isBefore(inicio) && !e.fechaEntrega.isAfter(fin))),
      if (Sesion.modoDemo) ..._entregasDeProyectosDemo(inicio, fin),
    ].where((e) => Sesion.esAdmin || !e.oculta).toList()
      ..sort((a, b) {
        if (a.oculta != b.oculta) return a.oculta ? 1 : -1;
        final porFecha = a.fechaEntrega.compareTo(b.fechaEntrega);
        if (porFecha != 0) return porFecha;
        if (a.entregada != b.entregada) return a.entregada ? 1 : -1;
        return a.unidad.toLowerCase().compareTo(b.unidad.toLowerCase());
      });
    return List.unmodifiable(lista);
  }

  /// Modo demo: lo mismo que calcula el backend, a partir de los proyectos en memoria.
  Iterable<EntregaSemana> _entregasDeProyectosDemo(DateTime inicio, DateTime fin) sync* {
    for (final p in ProyectosStore.instancia.activos) {
      final fecha = soloFecha(p.fechaEntrega);
      final enSemana = !fecha.isBefore(inicio) && !fecha.isAfter(fin);
      final atrasado = fecha.isBefore(inicio) && !p.terminado;
      if (!enSemana && !atrasado) continue;
      yield EntregaSemana(
        id: -(p.serverId ?? p.id.hashCode.abs()),
        origen: 'proyecto',
        proyectoId: p.serverId ?? p.id.hashCode.abs(),
        codigo: p.id,
        unidad: p.placa.isEmpty ? p.nombreCamion : '${p.nombreCamion} · ${p.placa}',
        cliente: p.nombreContraparte.isEmpty ? null : p.nombreContraparte,
        fechaEntrega: fecha,
        entregada: p.terminado,
        oculta: _ocultosDemo[p.id] == fecha,
      );
    }
  }

  /// Quita del tablero un proyecto (vuelve a aparecer si cambia su fecha de entrega).
  Future<String?> ocultarProyecto(EntregaSemana entrega) => _cambiarOculta(entrega, true);

  /// Regresa al tablero un proyecto que se había quitado.
  Future<String?> mostrarProyecto(EntregaSemana entrega) => _cambiarOculta(entrega, false);

  Future<String?> _cambiarOculta(EntregaSemana entrega, bool ocultar) async {
    if (!entrega.esProyecto) return null;
    if (Sesion.modoDemo) {
      if (ocultar) {
        _ocultosDemo[entrega.codigo ?? ''] = entrega.fechaEntrega;
      } else {
        _ocultosDemo.remove(entrega.codigo);
      }
      notifyListeners();
      return null;
    }
    try {
      final ruta = '/Tablero/entregas/proyecto/${entrega.proyectoId}/ocultar';
      await (ocultar ? _api.post(ruta) : _api.delete(ruta));
      for (final e in _entregas.where((e) => e.esProyecto && e.proyectoId == entrega.proyectoId)) {
        e.oculta = ocultar;
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  /// Notas vigentes (creadas después del último corte de las 7 pm).
  List<NotaCoordinacion> get coordinacion {
    final corte = ultimoCorte;
    final lista = _coordinacion.where((n) => !n.creado.isBefore(corte)).toList()..sort((a, b) => a.creado.compareTo(b.creado));
    return List.unmodifiable(lista);
  }

  List<Anuncio> get anuncios {
    final lista = [..._anuncios]..sort((a, b) => b.creado.compareTo(a.creado));
    return List.unmodifiable(lista);
  }

  Future<String?> cargar() async {
    if (Sesion.modoDemo) return null;
    _cargando = true;
    notifyListeners();
    try {
      final datos = Map<String, dynamic>.from(await _api.get('/Tablero') as Map);
      List<Map<String, dynamic>> lista(String clave) =>
          ((datos[clave] as List?) ?? const []).map((j) => Map<String, dynamic>.from(j as Map)).toList();
      _entregas
        ..clear()
        ..addAll(lista('entregas').map(EntregaSemana.fromJson));
      _coordinacion
        ..clear()
        ..addAll(lista('coordinacion').map(NotaCoordinacion.fromJson));
      _anuncios
        ..clear()
        ..addAll(lista('anuncios').map(Anuncio.fromJson));
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // Entregas de la semana
  // ------------------------------------------------------------------

  Future<String?> guardarEntrega(EntregaSemana entrega, {bool nueva = false}) async {
    if (Sesion.modoDemo) {
      if (nueva) {
        entrega.id = ++_idLocal;
        entrega.creadoPor = Sesion.nombre;
        _entregas.add(entrega);
      } else {
        _reemplazar(_entregas, entrega.id, entrega);
      }
      notifyListeners();
      return null;
    }
    try {
      final j = Map<String, dynamic>.from(await (nueva
          ? _api.post('/Tablero/entregas', entrega.toJson())
          : _api.put('/Tablero/entregas/${entrega.id}', entrega.toJson())) as Map);
      final guardada = EntregaSemana.fromJson(j);
      if (nueva) {
        _entregas.add(guardada);
      } else {
        _reemplazar(_entregas, guardada.id, guardada);
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<String?> marcarEntregada(EntregaSemana entrega, bool entregada) =>
      guardarEntrega(entrega.copia()..entregada = entregada);

  Future<String?> eliminarEntrega(EntregaSemana entrega) =>
      _eliminar('/Tablero/entregas/${entrega.id}', () => _entregas.removeWhere((e) => e.id == entrega.id));

  // ------------------------------------------------------------------
  // Coordinación operativa del día
  // ------------------------------------------------------------------

  Future<String?> guardarNota(NotaCoordinacion nota, {bool nueva = false}) async {
    if (Sesion.modoDemo) {
      if (nueva) {
        nota
          ..id = ++_idLocal
          ..creado = DateTime.now()
          ..creadoPor = Sesion.nombre;
        _coordinacion.add(nota);
      } else {
        _reemplazar(_coordinacion, nota.id, nota);
      }
      notifyListeners();
      return null;
    }
    try {
      final j = Map<String, dynamic>.from(await (nueva
          ? _api.post('/Tablero/coordinacion', nota.toJson())
          : _api.put('/Tablero/coordinacion/${nota.id}', nota.toJson())) as Map);
      final guardada = NotaCoordinacion.fromJson(j);
      if (nueva) {
        _coordinacion.add(guardada);
      } else {
        _reemplazar(_coordinacion, guardada.id, guardada);
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      if (e.status == 404) {
        _coordinacion.removeWhere((n) => n.id == nota.id);
        notifyListeners();
      }
      return e.mensaje;
    }
  }

  Future<String?> eliminarNota(NotaCoordinacion nota) =>
      _eliminar('/Tablero/coordinacion/${nota.id}', () => _coordinacion.removeWhere((n) => n.id == nota.id));

  // ------------------------------------------------------------------
  // Anuncios
  // ------------------------------------------------------------------

  Future<String?> guardarAnuncio(Anuncio anuncio, {bool nuevo = false}) async {
    if (Sesion.modoDemo) {
      if (nuevo) {
        anuncio
          ..id = ++_idLocal
          ..creado = DateTime.now()
          ..creadoPor = Sesion.nombre;
        _anuncios.add(anuncio);
      } else {
        anuncio.editado = DateTime.now();
        _reemplazar(_anuncios, anuncio.id, anuncio);
      }
      notifyListeners();
      return null;
    }
    try {
      final j = Map<String, dynamic>.from(await (nuevo
          ? _api.post('/Tablero/anuncios', anuncio.toJson())
          : _api.put('/Tablero/anuncios/${anuncio.id}', anuncio.toJson())) as Map);
      final guardado = Anuncio.fromJson(j);
      if (nuevo) {
        _anuncios.add(guardado);
      } else {
        _reemplazar(_anuncios, guardado.id, guardado);
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<String?> eliminarAnuncio(Anuncio anuncio) =>
      _eliminar('/Tablero/anuncios/${anuncio.id}', () => _anuncios.removeWhere((a) => a.id == anuncio.id));

  // ------------------------------------------------------------------

  Future<String?> _eliminar(String endpoint, void Function() quitarLocal) async {
    if (!Sesion.modoDemo) {
      try {
        await _api.delete(endpoint);
      } on ApiException catch (e) {
        if (e.status != 404) return e.mensaje; // Si ya no existía, igual se quita de la lista
      }
    }
    quitarLocal();
    notifyListeners();
    return null;
  }

  static void _reemplazar<T>(List<T> lista, int id, T nuevo) {
    final i = lista.indexWhere((x) => (x as dynamic).id == id);
    if (i >= 0) lista[i] = nuevo;
  }

  /// A las 7 pm se ocultan las notas del día (el backend también las borra) y se recarga.
  void _programarCorte() {
    _timerCorte?.cancel();
    final espera = siguienteCorte.difference(DateTime.now()) + const Duration(seconds: 5);
    _timerCorte = Timer(espera, () {
      _coordinacion.removeWhere((n) => n.creado.isBefore(ultimoCorte));
      notifyListeners();
      cargar();
      _programarCorte();
    });
  }

  void reiniciarDemo() {
    _entregas.clear();
    _ocultosDemo.clear();
    _coordinacion.clear();
    _anuncios.clear();
    _cargarEjemplos();
    notifyListeners();
  }

  void _cargarEjemplos() {
    final lunes = inicioSemana;
    final ahora = DateTime.now();
    // Las entregas de proyectos se calculan de los proyectos de ejemplo; esta es una manual
    _entregas.add(
      EntregaSemana(id: 3, unidad: 'International LT #7', cliente: 'Seguros Atlas (siniestro 4471)', fechaEntrega: lunes.add(const Duration(days: 4)), notas: 'Unidad de un taller externo'),
    );
    _coordinacion.addAll([
      NotaCoordinacion(id: 4, cuadrilla: 'Cuadrilla 1', asignacion: 'Hojalatería Kenworth #45 y apoyo en pintura', color: 'amarillo', creado: ahora),
      NotaCoordinacion(id: 5, cuadrilla: 'Cuadrilla 2', asignacion: 'Desarmado Cascadia #12', color: 'rosa', creado: ahora),
    ]);
    _anuncios.add(Anuncio(
      id: 6,
      titulo: 'Junta general',
      contenido: 'El viernes a las 8:00 am hay junta de seguridad en el área de pintura. Asistencia obligatoria.',
      creadoPor: 'Administrador',
      creado: ahora,
    ));
  }
}
