/// Modelo de dominio para OperacionModel.
class OperacionModel {
  final int? idOperacion;
  final int camionId;
  final int? usuarioId;
  final DateTime fechaInicio;
  final DateTime fechaEstimadaFinalizacion;
  final String? estadoOperacion;

  const OperacionModel({
    this.idOperacion,
    required this.camionId,
    this.usuarioId,
    required this.fechaInicio,
    required this.fechaEstimadaFinalizacion,
    this.estadoOperacion,
  });

  factory OperacionModel.fromJson(Map<String, dynamic> json) {
    return OperacionModel(
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

  OperacionModel copyWith({
    int? idOperacion,
    int? camionId,
    int? usuarioId,
    DateTime? fechaInicio,
    DateTime? fechaEstimadaFinalizacion,
    String? estadoOperacion,
  }) {
    return OperacionModel(
      idOperacion: idOperacion ?? this.idOperacion,
      camionId: camionId ?? this.camionId,
      usuarioId: usuarioId ?? this.usuarioId,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaEstimadaFinalizacion: fechaEstimadaFinalizacion ?? this.fechaEstimadaFinalizacion,
      estadoOperacion: estadoOperacion ?? this.estadoOperacion,
    );
  }
}
