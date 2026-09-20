/// Modelo de dominio para SolicitudCompraModel.
class SolicitudCompraModel {
  final int? idSolicitudCompra;
  final int operacionId;
  final int? usuarioId;
  final int? proveedorId;
  final String? nombrePiezasCotizadas;
  final int? cantidadPiezasCotizadas;
  final DateTime fechaSolicitud;

  const SolicitudCompraModel({
    this.idSolicitudCompra,
    required this.operacionId,
    this.usuarioId,
    this.proveedorId,
    this.nombrePiezasCotizadas,
    this.cantidadPiezasCotizadas,
    required this.fechaSolicitud,
  });

  factory SolicitudCompraModel.fromJson(Map<String, dynamic> json) {
    return SolicitudCompraModel(
      idSolicitudCompra: (json['id_solicitud_compra'] ?? json['idSolicitudCompra']) != null ? ((json['id_solicitud_compra'] ?? json['idSolicitudCompra']) as num).toInt() : null,
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      usuarioId: (json['usuario_id'] ?? json['usuarioId']) != null ? ((json['usuario_id'] ?? json['usuarioId']) as num).toInt() : null,
      proveedorId: (json['proveedor_id'] ?? json['proveedorId']) != null ? ((json['proveedor_id'] ?? json['proveedorId']) as num).toInt() : null,
      nombrePiezasCotizadas: (json['nombrePiezasCotizadas'] ?? json['nombre_piezas_cotizadas']) as String?,
      cantidadPiezasCotizadas: (json['cantidadPiezasCotizadas'] ?? json['cantidad_piezas_cotizadas']) != null ? ((json['cantidadPiezasCotizadas'] ?? json['cantidad_piezas_cotizadas']) as num).toInt() : null,
      fechaSolicitud: DateTime.parse((json['fechaSolicitud'] ?? json['fecha_solicitud']).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idSolicitudCompra != null) 'id_solicitud_compra': idSolicitudCompra,
      'operacion_id': operacionId,
      'usuario_id': usuarioId,
      'proveedor_id': proveedorId,
      'nombrePiezasCotizadas': nombrePiezasCotizadas,
      'cantidadPiezasCotizadas': cantidadPiezasCotizadas,
      'fechaSolicitud': fechaSolicitud.toIso8601String(),
    };
  }

  SolicitudCompraModel copyWith({
    int? idSolicitudCompra,
    int? operacionId,
    int? usuarioId,
    int? proveedorId,
    String? nombrePiezasCotizadas,
    int? cantidadPiezasCotizadas,
    DateTime? fechaSolicitud,
  }) {
    return SolicitudCompraModel(
      idSolicitudCompra: idSolicitudCompra ?? this.idSolicitudCompra,
      operacionId: operacionId ?? this.operacionId,
      usuarioId: usuarioId ?? this.usuarioId,
      proveedorId: proveedorId ?? this.proveedorId,
      nombrePiezasCotizadas: nombrePiezasCotizadas ?? this.nombrePiezasCotizadas,
      cantidadPiezasCotizadas: cantidadPiezasCotizadas ?? this.cantidadPiezasCotizadas,
      fechaSolicitud: fechaSolicitud ?? this.fechaSolicitud,
    );
  }
}
