import '../models/solicitud_compra_model.dart';

/// DTO para transferir datos completos o respuestas de API para SolicitudCompraModel.
class SolicitudCompraDto {
  final int? idSolicitudCompra;
  final int operacionId;
  final int? usuarioId;
  final int? proveedorId;
  final String? nombrePiezasCotizadas;
  final int? cantidadPiezasCotizadas;
  final DateTime fechaSolicitud;

  const SolicitudCompraDto({
    this.idSolicitudCompra,
    required this.operacionId,
    this.usuarioId,
    this.proveedorId,
    this.nombrePiezasCotizadas,
    this.cantidadPiezasCotizadas,
    required this.fechaSolicitud,
  });

  factory SolicitudCompraDto.fromJson(Map<String, dynamic> json) {
    return SolicitudCompraDto(
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

  SolicitudCompraModel toModel() {
    return SolicitudCompraModel(
      idSolicitudCompra: idSolicitudCompra,
      operacionId: operacionId,
      usuarioId: usuarioId,
      proveedorId: proveedorId,
      nombrePiezasCotizadas: nombrePiezasCotizadas,
      cantidadPiezasCotizadas: cantidadPiezasCotizadas,
      fechaSolicitud: fechaSolicitud,
    );
  }

  factory SolicitudCompraDto.fromModel(SolicitudCompraModel model) {
    return SolicitudCompraDto(
      idSolicitudCompra: model.idSolicitudCompra,
      operacionId: model.operacionId,
      usuarioId: model.usuarioId,
      proveedorId: model.proveedorId,
      nombrePiezasCotizadas: model.nombrePiezasCotizadas,
      cantidadPiezasCotizadas: model.cantidadPiezasCotizadas,
      fechaSolicitud: model.fechaSolicitud,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateSolicitudCompraDto {
  final int operacionId;
  final int? usuarioId;
  final int? proveedorId;
  final String? nombrePiezasCotizadas;
  final int? cantidadPiezasCotizadas;
  final DateTime fechaSolicitud;

  const CreateSolicitudCompraDto({
    required this.operacionId,
    this.usuarioId,
    this.proveedorId,
    this.nombrePiezasCotizadas,
    this.cantidadPiezasCotizadas,
    required this.fechaSolicitud,
  });

  factory CreateSolicitudCompraDto.fromJson(Map<String, dynamic> json) {
    return CreateSolicitudCompraDto(
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
      'operacion_id': operacionId,
      'usuario_id': usuarioId,
      'proveedor_id': proveedorId,
      'nombrePiezasCotizadas': nombrePiezasCotizadas,
      'cantidadPiezasCotizadas': cantidadPiezasCotizadas,
      'fechaSolicitud': fechaSolicitud.toIso8601String(),
    };
  }
}
