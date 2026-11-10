import 'package:flutter/foundation.dart';
import '../models/compras.dart';
import '../models/proyecto_taller.dart';
import 'api_client.dart';
import 'avisos_store.dart';
import 'sesion.dart';

/// Solicitudes de compra y sus órdenes. Con sesión real usa /api/Compra/solicitudes.
///
/// Flujo: un proyecto solicita lo que necesita → Compras abre la solicitud, llena la orden de compra
/// y la aprueba (o la rechaza con un motivo).
class ComprasStore extends ChangeNotifier {
  ComprasStore._() {
    _cargarEjemplos();
  }

  static final ComprasStore instancia = ComprasStore._();

  final ApiClient _api = ApiClient();
  final List<SolicitudCompra> _solicitudes = [];

  List<SolicitudCompra> get solicitudes => List.unmodifiable(_solicitudes);
  List<SolicitudCompra> get pendientes => _solicitudes.where((s) => s.estado == EstadoSolicitud.pendiente).toList();
  List<SolicitudCompra> get aprobadas => _solicitudes.where((s) => s.estado == EstadoSolicitud.aprobada).toList();
  List<SolicitudCompra> solicitudesDe(String proyectoId) => _solicitudes.where((s) => s.proyectoId == proyectoId).toList();

  /// Folio sugerido para la siguiente orden (en modo API lo asigna el servidor).
  String siguienteFolio() {
    final usados = _solicitudes
        .map((s) => int.tryParse((s.orden?.folio ?? '').replaceAll(RegExp(r'\D'), '')) ?? 0)
        .fold<int>(16336, (a, b) => a > b ? a : b);
    return 'OC${usados + 1}';
  }

  Future<String?> cargar() async {
    try {
      final datos = await _api.get('/Compra/solicitudes') as List;
      _solicitudes
        ..clear()
        ..addAll(datos.map((j) => SolicitudCompra.fromJson(Map<String, dynamic>.from(j as Map))));
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  void reiniciarDemo() {
    _solicitudes.clear();
    _cargarEjemplos();
    notifyListeners();
  }

  /// Deja el store vacío (el usuario no tiene acceso a esta área).
  void vaciar() {
    _solicitudes.clear();
    notifyListeners();
  }

  Future<String?> _enApi(Future<dynamic> Function() llamada) async {
    try {
      await llamada();
    } on ApiException catch (e) {
      return e.mensaje;
    }
    return cargar();
  }

  // ------------------------------------------------------------------ Solicitudes

  Future<String?> solicitar({
    required ProyectoTaller proyecto,
    required String descripcion,
    required double cantidad,
    required String unidad,
    String notas = '',
  }) async {
    if (descripcion.trim().isEmpty) return 'Escribe qué se necesita comprar.';
    if (cantidad <= 0) return 'La cantidad debe ser mayor a cero.';

    if (!Sesion.modoDemo) {
      return _enApi(() => _api.post('/Compra/solicitudes', {
            'proyectoId': proyecto.serverId,
            'descripcion': descripcion.trim(),
            'cantidad': cantidad,
            'unidad': unidad,
            'notas': notas.trim(),
          }));
    }

    final id = _solicitudes.isEmpty ? 1 : _solicitudes.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
    final solicitud = SolicitudCompra(
      id: id,
      proyectoId: proyecto.id,
      proyectoNombre: '${proyecto.nombreCamion} (${proyecto.placa})',
      solicitadoPor: Sesion.nombre.isEmpty ? 'Usuario' : Sesion.nombre,
      fecha: DateTime.now(),
      descripcion: descripcion.trim(),
      cantidad: cantidad,
      unidad: unidad,
      notas: notas.trim(),
    );
    _solicitudes.insert(0, solicitud);
    AvisosStore.instancia.registrarLocal(
      tipo: 'compra_solicitada',
      titulo: 'Nueva solicitud de compra',
      mensaje: '${proyecto.nombreCamion}: ${solicitud.descripcion} (${_cantidad(cantidad)} $unidad)',
      roles: const ['Admin', 'Compras_Admin'],
    );
    notifyListeners();
    return null;
  }

  /// Compras completa la orden y aprueba la solicitud.
  Future<String?> aprobar(SolicitudCompra solicitud, OrdenCompraDoc orden) async {
    if (solicitud.estado != EstadoSolicitud.pendiente) return 'La solicitud ya fue atendida.';
    if (orden.proveedorId == null) return 'Elige el proveedor.';
    if (orden.partidas.isEmpty) return 'Agrega al menos un artículo.';
    if (orden.partidas.any((p) => p.nombre.trim().isEmpty || p.unidades <= 0)) return 'Revisa los artículos: nombre y unidades son obligatorios.';
    if (orden.partidas.any((p) => p.precio < 0 || p.descuento < 0)) return 'Los precios y descuentos no pueden ser negativos.';

    if (!Sesion.modoDemo) return _enApi(() => _api.post('/Compra/solicitudes/${solicitud.id}/aprobar', orden.toJson()));

    solicitud
      ..orden = orden
      ..estado = EstadoSolicitud.aprobada;
    AvisosStore.instancia.registrarLocal(
      tipo: 'compra_aprobada',
      titulo: 'Compra aprobada',
      mensaje: '${orden.folio}: ${orden.partidas.map((p) => p.nombre).join(', ')} para ${solicitud.proyectoNombre}',
      roles: const ['Admin', 'Proyecto_Lider'],
    );
    notifyListeners();
    return null;
  }

  Future<String?> rechazar(SolicitudCompra solicitud, String motivo) async {
    if (solicitud.estado != EstadoSolicitud.pendiente) return 'La solicitud ya fue atendida.';
    if (motivo.trim().isEmpty) return 'Indica el motivo del rechazo.';
    if (!Sesion.modoDemo) return _enApi(() => _api.post('/Compra/solicitudes/${solicitud.id}/rechazar', {'motivo': motivo.trim()}));

    solicitud
      ..estado = EstadoSolicitud.rechazada
      ..motivoRechazo = motivo.trim();
    notifyListeners();
    return null;
  }

  Future<String?> eliminar(SolicitudCompra solicitud) async {
    if (solicitud.estado == EstadoSolicitud.aprobada) return 'Una solicitud aprobada no se puede eliminar.';
    if (!Sesion.modoDemo) return _enApi(() => _api.delete('/Compra/solicitudes/${solicitud.id}'));
    _solicitudes.remove(solicitud);
    notifyListeners();
    return null;
  }

  static String _cantidad(double c) => c == c.roundToDouble() ? c.toStringAsFixed(0) : c.toString();

  // ------------------------------------------------------------------ Datos de ejemplo (modo demo)

  void _cargarEjemplos() {
    final hoy = DateTime.now();
    final aprobada = SolicitudCompra(
      id: 1,
      proyectoId: 'PC-001',
      proyectoNombre: 'Volvo VNL 2019 (DUR-4821)',
      solicitadoPor: 'Sergio Urey Morales',
      fecha: hoy.subtract(const Duration(days: 2)),
      descripcion: 'Electrodo 6010 de 1/8" Infra',
      cantidad: 10,
      unidad: 'Kilogramo',
      estado: EstadoSolicitud.aprobada,
      orden: OrdenCompraDoc(
        folio: 'OC16336',
        fecha: hoy.subtract(const Duration(days: 1)),
        proveedorId: 1,
        proveedorNombre: 'Refacciones Diésel del Norte',
        proveedorDireccion: 'Blvd. Miguel Alemán 1450, Gómez Palacio, Dgo.',
        entrega: hoy.subtract(const Duration(days: 1)),
        condiciones: 'Contado',
        partidas: [PartidaOrden(articulo: 'HER-069', nombre: 'Electrodo 6010 de 1/8" Infra', unidad: 'Kilogramo', unidades: 10, precio: 79.10)],
      ),
    );
    _solicitudes.addAll([
      SolicitudCompra(
        id: 3,
        proyectoId: 'PA-001',
        proyectoNombre: 'Freightliner Cascadia (NL-77215)',
        solicitadoPor: 'Roberto Gómez',
        fecha: hoy.subtract(const Duration(hours: 3)),
        descripcion: 'Faro principal LED delantero',
        cantidad: 2,
        unidad: 'Pieza',
        notas: 'Urgente: entrega a aseguradora en 2 días',
      ),
      SolicitudCompra(
        id: 2,
        proyectoId: 'PC-002',
        proyectoNombre: 'Kenworth T680 (COA-1093)',
        solicitadoPor: 'Carlos Martínez',
        fecha: hoy.subtract(const Duration(days: 1)),
        descripcion: 'Compresor de aire Wabco',
        cantidad: 1,
        unidad: 'Pieza',
      ),
      aprobada,
    ]);
  }
}
