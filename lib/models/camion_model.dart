/// Modelo de dominio para CamionModel.
class CamionModel {
  final int? idCamion;
  final int clienteId;
  final String placas;
  final String? marca;
  final String? modelo;
  final DateTime fechaEntrada;
  final DateTime tiempoEsperado;

  const CamionModel({
    this.idCamion,
    required this.clienteId,
    required this.placas,
    this.marca,
    this.modelo,
    required this.fechaEntrada,
    required this.tiempoEsperado,
  });

  factory CamionModel.fromJson(Map<String, dynamic> json) {
    return CamionModel(
      idCamion: (json['id_camion'] ?? json['idCamion']) != null ? ((json['id_camion'] ?? json['idCamion']) as num).toInt() : null,
      clienteId: ((json['cliente_id'] ?? json['clienteId']) as num).toInt(),
      placas: ((json['placas']) ?? '').toString(),
      marca: (json['marca']) as String?,
      modelo: (json['modelo']) as String?,
      fechaEntrada: DateTime.parse((json['fechaEntrada'] ?? json['fecha_entrada']).toString()),
      tiempoEsperado: DateTime.parse((json['tiempoEsperado'] ?? json['tiempo_esperado']).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idCamion != null) 'id_camion': idCamion,
      'cliente_id': clienteId,
      'placas': placas,
      'marca': marca,
      'modelo': modelo,
      'fechaEntrada': fechaEntrada.toIso8601String(),
      'tiempoEsperado': tiempoEsperado.toIso8601String(),
    };
  }

  CamionModel copyWith({
    int? idCamion,
    int? clienteId,
    String? placas,
    String? marca,
    String? modelo,
    DateTime? fechaEntrada,
    DateTime? tiempoEsperado,
  }) {
    return CamionModel(
      idCamion: idCamion ?? this.idCamion,
      clienteId: clienteId ?? this.clienteId,
      placas: placas ?? this.placas,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      fechaEntrada: fechaEntrada ?? this.fechaEntrada,
      tiempoEsperado: tiempoEsperado ?? this.tiempoEsperado,
    );
  }
}
