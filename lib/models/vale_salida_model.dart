/// Modelo de dominio para ValeSalidaModel.
class ValeSalidaModel {
  final int? idVale;
  final int operacionId;
  final int? usuarioId;
  final String entregadoA;
  final DateTime fechaEntrega;

  const ValeSalidaModel({
    this.idVale,
    required this.operacionId,
    this.usuarioId,
    required this.entregadoA,
    required this.fechaEntrega,
  });

  factory ValeSalidaModel.fromJson(Map<String, dynamic> json) {
    return ValeSalidaModel(
      idVale: (json['id_vale'] ?? json['idVale']) != null ? ((json['id_vale'] ?? json['idVale']) as num).toInt() : null,
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      usuarioId: (json['usuario_id'] ?? json['usuarioId']) != null ? ((json['usuario_id'] ?? json['usuarioId']) as num).toInt() : null,
      entregadoA: ((json['entregadoA'] ?? json['entregado_a']) ?? '').toString(),
      fechaEntrega: DateTime.parse((json['fechaEntrega'] ?? json['fecha_entrega']).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idVale != null) 'id_vale': idVale,
      'operacion_id': operacionId,
      'usuario_id': usuarioId,
      'entregadoA': entregadoA,
      'fechaEntrega': fechaEntrega.toIso8601String(),
    };
  }

  ValeSalidaModel copyWith({
    int? idVale,
    int? operacionId,
    int? usuarioId,
    String? entregadoA,
    DateTime? fechaEntrega,
  }) {
    return ValeSalidaModel(
      idVale: idVale ?? this.idVale,
      operacionId: operacionId ?? this.operacionId,
      usuarioId: usuarioId ?? this.usuarioId,
      entregadoA: entregadoA ?? this.entregadoA,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
    );
  }
}
