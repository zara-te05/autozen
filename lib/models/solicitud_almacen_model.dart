/// Modelo de dominio para SolicitudAlmacenModel.
class SolicitudAlmacenModel {
  final int? idSolicitudAlmacen;
  final int almacenId;
  final int operacionId;
  final int? cantidadSolicitada;
  final DateTime fechaSolicitud;

  const SolicitudAlmacenModel({
    this.idSolicitudAlmacen,
    required this.almacenId,
    required this.operacionId,
    this.cantidadSolicitada,
    required this.fechaSolicitud,
  });

  factory SolicitudAlmacenModel.fromJson(Map<String, dynamic> json) {
    return SolicitudAlmacenModel(
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

  SolicitudAlmacenModel copyWith({
    int? idSolicitudAlmacen,
    int? almacenId,
    int? operacionId,
    int? cantidadSolicitada,
    DateTime? fechaSolicitud,
  }) {
    return SolicitudAlmacenModel(
      idSolicitudAlmacen: idSolicitudAlmacen ?? this.idSolicitudAlmacen,
      almacenId: almacenId ?? this.almacenId,
      operacionId: operacionId ?? this.operacionId,
      cantidadSolicitada: cantidadSolicitada ?? this.cantidadSolicitada,
      fechaSolicitud: fechaSolicitud ?? this.fechaSolicitud,
    );
  }
}
