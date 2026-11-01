import 'package:flutter/foundation.dart';
import '../models/proyecto_taller.dart';
import 'api_client.dart';
import 'avisos_store.dart';
import 'fotos_service.dart';
import 'sesion.dart';

/// Estado compartido de los proyectos del taller.
///
/// En modo demo trabaja en memoria; con sesión real cada operación llama a /api/Proyecto.
/// Los métodos que pueden fallar devuelven un mensaje de error, o null si todo salió bien.
class ProyectosStore extends ChangeNotifier {
  ProyectosStore._() {
    _cargarEjemplos();
  }

  static final ProyectosStore instancia = ProyectosStore._();

  final ApiClient _api = ApiClient();
  final List<ProyectoTaller> _proyectos = [];
  int _siguienteIdDemo = 100;

  List<ProyectoTaller> listar(TipoProyecto tipo, {required bool archivados}) {
    return _proyectos.where((p) => p.tipo == tipo && p.archivado == archivados).toList();
  }

  /// Proyectos activos de ambos tipos, para elegir destino en vales y compras.
  List<ProyectoTaller> get activos => _proyectos.where((p) => !p.archivado).toList();

  /// Todos los proyectos (para notificaciones).
  List<ProyectoTaller> get todos => List.unmodifiable(_proyectos);

  ProyectoTaller? porId(String id) {
    for (final p in _proyectos) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Código para un proyecto nuevo en modo demo (en modo API lo asigna el servidor).
  String siguienteId(TipoProyecto tipo) {
    final consecutivo = _proyectos.where((p) => p.tipo == tipo).length + 1;
    return '${tipo.prefijoId}-${consecutivo.toString().padLeft(3, '0')}';
  }

  // ------------------------------------------------------------------ Carga

  Future<String?> cargar() async {
    try {
      final datos = await _api.get('/Proyecto') as List;
      final nuevos = datos.map((j) => ProyectoTaller.fromJson(Map<String, dynamic>.from(j as Map))).toList();
      // Se actualizan los objetos existentes para que las pantallas abiertas vean los cambios
      final existentes = {for (final p in _proyectos) p.serverId: p};
      _proyectos
        ..clear()
        ..addAll(nuevos.map((n) {
          final previo = existentes[n.serverId];
          if (previo == null || previo.id != n.id) return n;
          previo.copiarDe(n);
          return previo;
        }));
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  void reiniciarDemo() {
    _proyectos.clear();
    _siguienteIdDemo = 100;
    _cargarEjemplos();
    notifyListeners();
  }

  // ------------------------------------------------------------------ Escritura

  /// Crea el proyecto con los datos de la Evaluación de Daños y sube sus fotos.
  /// Si el proyecto se creó pero alguna foto falló, devuelve el proyecto y un aviso.
  Future<({String? error, ProyectoTaller? proyecto})> crear(ProyectoTaller borrador) async {
    if (Sesion.modoDemo) {
      borrador.serverId = _siguienteIdDemo++;
      _proyectos.insert(0, borrador);
      AvisosStore.instancia.registrarLocal(
        tipo: 'proyecto_nuevo',
        titulo: 'Se abrió un nuevo proyecto',
        mensaje: '${borrador.id}: ${borrador.nombreCamion} (${borrador.placa}) • ${borrador.nombreContraparte}',
        roles: const ['Admin'],
      );
      notifyListeners();
      return (error: null, proyecto: borrador);
    }

    try {
      final json = await _api.post('/Proyecto', borrador.toJsonGuardar(incluirEvaluacion: true));
      final creado = ProyectoTaller.fromJson(Map<String, dynamic>.from(json as Map));
      int fallidas = 0;
      String? motivo;
      for (final ruta in borrador.fotos) {
        try {
          final foto = await _api.subirArchivo('/Proyecto/${creado.serverId}/fotos', ruta);
          creado.fotos.add((foto as Map)['url'] as String);
          await FotosService.borrar(ruta); // ya está en el servidor
        } on ApiException catch (e) {
          fallidas++;
          motivo = e.mensaje;
        }
      }
      _proyectos.insert(0, creado);
      notifyListeners();
      return (
        error: fallidas == 0 ? null : 'El proyecto se creó, pero $fallidas foto(s) no se subieron: $motivo',
        proyecto: creado,
      );
    } on ApiException catch (e) {
      return (error: e.mensaje, proyecto: null);
    }
  }

  /// Guarda los cambios de [cambios] (copia editada) en [original].
  Future<String?> actualizarProyecto(ProyectoTaller original, ProyectoTaller cambios) async {
    if (Sesion.modoDemo) {
      original.copiarDe(cambios..serverId = original.serverId);
      AvisosStore.instancia.registrarLocal(
        tipo: 'proyecto_editado',
        titulo: 'Se editó un proyecto',
        mensaje: '${original.id}: ${original.nombreCamion} (${original.placa})',
        roles: const ['Admin'],
      );
      notifyListeners();
      return null;
    }
    return _ejecutar(original, () => _api.put('/Proyecto/${original.serverId}', cambios.toJsonGuardar(incluirEvaluacion: false)));
  }

  Future<String?> archivar(ProyectoTaller proyecto) async {
    if (Sesion.modoDemo) {
      proyecto.archivado = true;
      notifyListeners();
      return null;
    }
    return _ejecutar(proyecto, () => _api.post('/Proyecto/${proyecto.serverId}/archivar'));
  }

  Future<String?> restaurar(ProyectoTaller proyecto) async {
    if (Sesion.modoDemo) {
      proyecto.archivado = false;
      notifyListeners();
      return null;
    }
    return _ejecutar(proyecto, () => _api.post('/Proyecto/${proyecto.serverId}/restaurar'));
  }

  Future<String?> avanzarEtapa(ProyectoTaller proyecto) async {
    if (proyecto.terminado) return null;
    if (Sesion.modoDemo) {
      proyecto.etapaActual++;
      notifyListeners();
      return null;
    }
    return _ejecutar(proyecto, () => _api.post('/Proyecto/${proyecto.serverId}/avanzar'));
  }

  Future<String?> agregarFoto(ProyectoTaller proyecto, String rutaLocal) async {
    if (Sesion.modoDemo) {
      proyecto.fotos.add(rutaLocal);
      notifyListeners();
      return null;
    }
    try {
      final foto = await _api.subirArchivo('/Proyecto/${proyecto.serverId}/fotos', rutaLocal);
      proyecto.fotos.add((foto as Map)['url'] as String);
      await FotosService.borrar(rutaLocal);
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<String?> quitarFoto(ProyectoTaller proyecto, String ruta) async {
    final esRemota = ruta.startsWith('/api/') || ruta.startsWith('http');
    if (esRemota && !Sesion.modoDemo) {
      try {
        await _api.delete(ruta.replaceFirst(RegExp(r'^.*?/api'), ''));
      } on ApiException catch (e) {
        return e.mensaje;
      }
    } else {
      await FotosService.borrar(ruta);
    }
    proyecto.fotos.remove(ruta);
    notifyListeners();
    return null;
  }

  // ------------------------------------------------------------------ PDFs de la aseguradora

  static const int maxBytesPdf = 20 * 1024 * 1024;

  Future<String?> agregarDocumento(ProyectoTaller proyecto, {required String ruta, required String nombre, required int tamano}) async {
    if (!nombre.toLowerCase().endsWith('.pdf')) return 'Solo se pueden subir archivos PDF.';
    if (tamano > maxBytesPdf) return 'El PDF pesa más de 20 MB.';
    if (Sesion.modoDemo) {
      proyecto.documentos.add(DocumentoProyecto(nombre: nombre, ruta: ruta, tamano: tamano, fecha: DateTime.now()));
      notifyListeners();
      return null;
    }
    try {
      final json = await _api.subirArchivo('/Proyecto/${proyecto.serverId}/documentos', ruta, nombreArchivo: nombre);
      proyecto.documentos.add(DocumentoProyecto.fromJson(Map<String, dynamic>.from(json as Map)));
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  Future<String?> quitarDocumento(ProyectoTaller proyecto, DocumentoProyecto documento) async {
    if (documento.remoto && !Sesion.modoDemo) {
      try {
        await _api.delete(documento.ruta.replaceFirst(RegExp(r'^.*?/api'), ''));
      } on ApiException catch (e) {
        return e.mensaje;
      }
    }
    proyecto.documentos.remove(documento);
    notifyListeners();
    return null;
  }

  /// Ejecuta una llamada que devuelve el proyecto actualizado y lo copia sobre el original.
  Future<String?> _ejecutar(ProyectoTaller proyecto, Future<dynamic> Function() llamada) async {
    try {
      final json = await llamada();
      proyecto.copiarDe(ProyectoTaller.fromJson(Map<String, dynamic>.from(json as Map)));
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  // ------------------------------------------------------------------ Datos de ejemplo (modo demo)

  void _cargarEjemplos() {
    final hoy = DateTime.now();
    _proyectos.addAll([
      ProyectoTaller(
        id: 'PC-001',
        serverId: 1,
        tipo: TipoProyecto.cliente,
        nombreCamion: 'Volvo VNL 2019',
        cliente: 'Transportes del Norte',
        placa: 'DUR-4821',
        responsable: 'Sergio Urey Morales',
        fechaIngreso: hoy.subtract(const Duration(days: 6)),
        etapas: ProyectoTaller.etapasPorDefecto(TipoProyecto.cliente),
        etapaActual: 1,
      ),
      ProyectoTaller(
        id: 'PC-002',
        serverId: 2,
        tipo: TipoProyecto.cliente,
        nombreCamion: 'Kenworth T680',
        cliente: 'Logística Express',
        placa: 'COA-1093',
        responsable: 'Carlos Martínez',
        fechaIngreso: hoy.subtract(const Duration(days: 9)),
        etapas: ProyectoTaller.etapasPorDefecto(TipoProyecto.cliente),
        etapaActual: 2,
      ),
      ProyectoTaller(
        id: 'PA-001',
        serverId: 3,
        tipo: TipoProyecto.aseguradora,
        nombreCamion: 'Freightliner Cascadia',
        cliente: '',
        placa: 'NL-77215',
        responsable: 'Roberto Gómez',
        aseguradora: 'Seguros Atlas',
        numeroSiniestro: 'SIN-2026-0481',
        fechaIngreso: hoy.subtract(const Duration(days: 2)),
        fechaEntregaComprometida: hoy.add(const Duration(days: 2)),
        etapas: ProyectoTaller.repartirDias(ProyectoTaller.etapasPorDefecto(TipoProyecto.aseguradora), 4),
        etapaActual: 1,
      ),
    ]);
  }
}
