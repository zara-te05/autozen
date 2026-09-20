import '../models/solicitud_almacen_model.dart';

/// DTO para transferir datos completos o respuestas de API para SolicitudAlmacenModel.
class SolicitudAlmacenDto {
  final int? idSolicitudAlmacen;
  final int almacenId;
  final int operacionId;
  final int? cantidadSolicitada;
  final DateTime fechaSolicitud;

  const SolicitudAlmacenDto({
    this.idSolicitudAlmacen,
    required this.almacenId,
    required this.operacionId,
    this.cantidadSolicitada,
    required this.fechaSolicitud,
  });

  factory SolicitudAlmacenDto.fromJson(Map<String, dynamic> json) {
    return SolicitudAlmacenDto(
      idSolicitudAlmacen: (json['id_solicitud_almacen'] ?? json['idSolicitudAlmacen']) != null ? ((json['id_solicitud_almacen'] ?? json['idSolicitudAlmacen']) as num).toInt() : null,
      almacenId: ((json['almacen_id'] ?? json['almacenId']) as num).toInt(),
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      cantidadSolicitada: (json['cantidadSolicitada'] ?? json['cantidad_solicitada']) != null ? ((json['cantidadSolicitada'] ?? json['cantidad_solicitada']) as num).toInt() : null,
      fechaSolicitud: DateTime.parse((json['fechaSolicitud'] ?? json['fecha_solicitud']).toString()),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (idSolicitudAlmacen != null) 'id_solicitud_almacen': idSolicitudAlmacen,
      'almacen_id': almacenId,
      'operacion_id': operacionId,
      'cantidadSolicitada': cantidadSolicitada,
      'fechaSolicitud': fechaSolicitud.toIso8601String(),
    };
  }

  SolicitudAlmacenModel toModel() {
    return SolicitudAlmacenModel(
      idSolicitudAlmacen: idSolicitudAlmacen,
      almacenId: almacenId,
      operacionId: operacionId,
      cantidadSolicitada: cantidadSolicitada,
      fechaSolicitud: fechaSolicitud,
    );
  }

  factory SolicitudAlmacenDto.fromModel(SolicitudAlmacenModel model) {
    return SolicitudAlmacenDto(
      idSolicitudAlmacen: model.idSolicitudAlmacen,
      almacenId: model.almacenId,
      operacionId: model.operacionId,
      cantidadSolicitada: model.cantidadSolicitada,
      fechaSolicitud: model.fechaSolicitud,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateSolicitudAlmacenDto {
  final int almacenId;
  final int operacionId;
  final int? cantidadSolicitada;
  final DateTime fechaSolicitud;

  const CreateSolicitudAlmacenDto({
    required this.almacenId,
    required this.operacionId,
    this.cantidadSolicitada,
    required this.fechaSolicitud,
  });

  factory CreateSolicitudAlmacenDto.fromJson(Map<String, dynamic> json) {
    return CreateSolicitudAlmacenDto(
      almacenId: ((json['almacen_id'] ?? json['almacenId']) as num).toInt(),
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      cantidadSolicitada: (json['cantidadSolicitada'] ?? json['cantidad_solicitada']) != null ? ((json['cantidadSolicitada'] ?? json['cantidad_solicitada']) as num).toInt() : null,
      fechaSolicitud: DateTime.parse((json['fechaSolicitud'] ?? json['fecha_solicitud']).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'almacen_id': almacenId,
      'operacion_id': operacionId,
      'cantidadSolicitada': cantidadSolicitada,
      'fechaSolicitud': fechaSolicitud.toIso8601String(),
    };
  }
}
