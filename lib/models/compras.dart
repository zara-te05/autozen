/// Solicitudes de compra y la orden de compra que llena el departamento de Compras.
library;

import '../utils/numero_a_letras.dart';

enum EstadoSolicitud { pendiente, aprobada, rechazada }

extension EstadoSolicitudTexto on EstadoSolicitud {
  String get nombre => switch (this) {
        EstadoSolicitud.pendiente => 'Pendiente',
        EstadoSolicitud.aprobada => 'Aprobada',
        EstadoSolicitud.rechazada => 'Rechazada',
      };

  static EstadoSolicitud desdeTexto(String? t) => EstadoSolicitud.values.firstWhere(
        (e) => e.nombre.toLowerCase() == (t ?? '').toLowerCase(),
        orElse: () => EstadoSolicitud.pendiente,
      );
}

/// Renglón de la orden de compra (Artículo, Nombre, U.med., Unidades, Precio, Descto., Importe).
class PartidaOrden {
  String articulo;
  String nombre;
  String unidad;
  double unidades;
  double precio;

  /// Descuento en pesos para el renglón.
  double descuento;

  PartidaOrden({
    this.articulo = '',
    required this.nombre,
    this.unidad = 'Pieza',
    this.unidades = 1,
    this.precio = 0,
    this.descuento = 0,
  });

  double get importe => (unidades * precio - descuento).clamp(0, double.infinity).toDouble();

  PartidaOrden copia() =>
      PartidaOrden(articulo: articulo, nombre: nombre, unidad: unidad, unidades: unidades, precio: precio, descuento: descuento);

  factory PartidaOrden.fromJson(Map<String, dynamic> j) => PartidaOrden(
        articulo: j['articulo'] as String? ?? '',
        nombre: j['nombre'] as String? ?? '',
        unidad: j['unidad'] as String? ?? 'Pieza',
        unidades: (j['unidades'] as num?)?.toDouble() ?? 1,
        precio: (j['precio'] as num?)?.toDouble() ?? 0,
        descuento: (j['descuento'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'articulo': articulo, 'nombre': nombre, 'unidad': unidad, 'unidades': unidades, 'precio': precio, 'descuento': descuento};
}

/// Unidades de medida para la orden de compra.
const List<String> unidadesOrden = ['Pieza', 'Kilogramo', 'Litro', 'Metro', 'Juego', 'Caja', 'Servicio'];

const List<String> condicionesPago = ['Contado', 'Crédito 15 días', 'Crédito 30 días', 'Crédito 60 días'];

/// La orden de compra tal como la hoja impresa.
class OrdenCompraDoc {
  String folio;
  DateTime fecha;
  int? proveedorId;
  String proveedorNombre;
  String proveedorDireccion;
  String consignatario;
  DateTime entrega;
  String condiciones;
  String viaEmbarque;
  List<PartidaOrden> partidas;

  /// Tasa de IVA (0.16 = 16 %). 0 para no aplicar IVA.
  double tasaIva;
  String observaciones;

  OrdenCompraDoc({
    required this.folio,
    required this.fecha,
    this.proveedorId,
    this.proveedorNombre = '',
    this.proveedorDireccion = '',
    this.consignatario = '',
    required this.entrega,
    this.condiciones = 'Contado',
    this.viaEmbarque = '',
    required this.partidas,
    this.tasaIva = 0.16,
    this.observaciones = '',
  });

  double get subtotal => partidas.fold(0.0, (s, p) => s + p.importe);
  double get iva => double.parse((subtotal * tasaIva).toStringAsFixed(2));
  double get total => subtotal + iva;
  String get totalConLetra => importeConLetra(total);

  factory OrdenCompraDoc.fromJson(Map<String, dynamic> j) => OrdenCompraDoc(
        folio: j['folio'] as String? ?? '',
        fecha: DateTime.parse(j['fecha'] as String),
        proveedorId: (j['proveedorId'] as num?)?.toInt(),
        proveedorNombre: j['proveedorNombre'] as String? ?? '',
        proveedorDireccion: j['proveedorDireccion'] as String? ?? '',
        consignatario: j['consignatario'] as String? ?? '',
        entrega: DateTime.parse(j['entrega'] as String),
        condiciones: j['condiciones'] as String? ?? 'Contado',
        viaEmbarque: j['viaEmbarque'] as String? ?? '',
        partidas: ((j['partidas'] as List?) ?? const []).map((p) => PartidaOrden.fromJson(Map<String, dynamic>.from(p as Map))).toList(),
        tasaIva: (j['tasaIva'] as num?)?.toDouble() ?? 0.16,
        observaciones: j['observaciones'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'fecha': fecha.toIso8601String(),
        'proveedorId': proveedorId,
        'consignatario': consignatario,
        'entrega': entrega.toIso8601String(),
        'condiciones': condiciones,
        'viaEmbarque': viaEmbarque,
        'partidas': partidas.map((p) => p.toJson()).toList(),
        'tasaIva': tasaIva,
        'observaciones': observaciones,
      };
}

/// Lo que un proyecto pide comprar. Compras la atiende generando la orden o la rechaza.
class SolicitudCompra {
  final int id;
  final String proyectoId;
  final String proyectoNombre;
  final String solicitadoPor;
  final DateTime fecha;

  /// Nombre de lo que se necesita.
  final String descripcion;
  final double cantidad;
  final String unidad;
  final String notas;
  EstadoSolicitud estado;
  OrdenCompraDoc? orden;
  String? motivoRechazo;

  SolicitudCompra({
    required this.id,
    required this.proyectoId,
    required this.proyectoNombre,
    required this.solicitadoPor,
    required this.fecha,
    required this.descripcion,
    this.cantidad = 1,
    this.unidad = 'Pieza',
    this.notas = '',
    this.estado = EstadoSolicitud.pendiente,
    this.orden,
    this.motivoRechazo,
  });

  String get codigo => 'SC-${id.toString().padLeft(4, '0')}';

  factory SolicitudCompra.fromJson(Map<String, dynamic> j) => SolicitudCompra(
        id: (j['id'] as num).toInt(),
        proyectoId: j['proyectoCodigo'] as String? ?? '',
        proyectoNombre: j['proyectoNombre'] as String? ?? '',
        solicitadoPor: j['solicitadoPor'] as String? ?? '',
        fecha: DateTime.parse(j['fecha'] as String),
        descripcion: j['descripcion'] as String? ?? '',
        cantidad: (j['cantidad'] as num?)?.toDouble() ?? 1,
        unidad: j['unidad'] as String? ?? 'Pieza',
        notas: j['notas'] as String? ?? '',
        estado: EstadoSolicitudTexto.desdeTexto(j['estado'] as String?),
        orden: j['orden'] == null ? null : OrdenCompraDoc.fromJson(Map<String, dynamic>.from(j['orden'] as Map)),
        motivoRechazo: j['motivoRechazo'] as String?,
      );
}
