import '../models/operacion_model.dart';

/// DTO para transferir datos completos o respuestas de API para OperacionModel.
class OperacionDto {
  final int? idOperacion;
  final int camionId;
  final int? usuarioId;
  final DateTime fechaInicio;
  final DateTime fechaEstimadaFinalizacion;
  final String? estadoOperacion;

  const OperacionDto({
    this.idOperacion,
    required this.camionId,
    this.usuarioId,
    required this.fechaInicio,
    required this.fechaEstimadaFinalizacion,
    this.estadoOperacion,
  });

  factory OperacionDto.fromJson(Map<String, dynamic> json) {
    return OperacionDto(
      idOperacion: (json['id_operacion'] ?? json['idOperacion']) != null ? ((json['id_operacion'] ?? json['idOperacion']) as num).toInt() : null,
      camionId: ((json['camion_id'] ?? json['camionId']) as num).toInt(),
      usuarioId: (json['usuario_id'] ?? json['usuarioId']) != null ? ((json['usuario_id'] ?? json['usuarioId']) as num).toInt() : null,
      fechaInicio: DateTime.parse((json['fechaInicio'] ?? json['fecha_inicio']).toString()),
      fechaEstimadaFinalizacion: DateTime.parse((json['fechaEstimadaFinalizacion'] ?? json['fecha_estimada_finalizacion']).toString()),
      estadoOperacion: (json['estadoOperacion'] ?? json['estado_operacion']) as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (idOperacion != null) 'id_operacion': idOperacion,
      'camion_id': camionId,
      'usuario_id': usuarioId,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaEstimadaFinalizacion': fechaEstimadaFinalizacion.toIso8601String(),
      'estadoOperacion': estadoOperacion,
    };
  }

  OperacionModel toModel() {
    return OperacionModel(
      idOperacion: idOperacion,
      camionId: camionId,
      usuarioId: usuarioId,
      fechaInicio: fechaInicio,
      fechaEstimadaFinalizacion: fechaEstimadaFinalizacion,
      estadoOperacion: estadoOperacion,
    );
  }

  factory OperacionDto.fromModel(OperacionModel model) {
    return OperacionDto(
      idOperacion: model.idOperacion,
      camionId: model.camionId,
      usuarioId: model.usuarioId,
      fechaInicio: model.fechaInicio,
      fechaEstimadaFinalizacion: model.fechaEstimadaFinalizacion,
      estadoOperacion: model.estadoOperacion,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateOperacionDto {
  final int camionId;
  final int? usuarioId;
  final DateTime fechaInicio;
  final DateTime fechaEstimadaFinalizacion;
  final String? estadoOperacion;

  const CreateOperacionDto({
    required this.camionId,
    this.usuarioId,
    required this.fechaInicio,
    required this.fechaEstimadaFinalizacion,
    this.estadoOperacion,
  });

  factory CreateOperacionDto.fromJson(Map<String, dynamic> json) {
    return CreateOperacionDto(
      camionId: ((json['camion_id'] ?? json['camionId']) as num).toInt(),
      usuarioId: (json['usuario_id'] ?? json['usuarioId']) != null ? ((json['usuario_id'] ?? json['usuarioId']) as num).toInt() : null,
      fechaInicio: DateTime.parse((json['fechaInicio'] ?? json['fecha_inicio']).toString()),
      fechaEstimadaFinalizacion: DateTime.parse((json['fechaEstimadaFinalizacion'] ?? json['fecha_estimada_finalizacion']).toString()),
      estadoOperacion: (json['estadoOperacion'] ?? json['estado_operacion']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'camion_id': camionId,
      'usuario_id': usuarioId,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaEstimadaFinalizacion': fechaEstimadaFinalizacion.toIso8601String(),
      'estadoOperacion': estadoOperacion,
    };
  }
}
