import '../models/camion_model.dart';

/// DTO para transferir datos completos o respuestas de API para CamionModel.
class CamionDto {
  final int? idCamion;
  final int clienteId;
  final String placas;
  final String? marca;
  final String? modelo;
  final DateTime fechaEntrada;
  final DateTime tiempoEsperado;

  const CamionDto({
    this.idCamion,
    required this.clienteId,
    required this.placas,
    this.marca,
    this.modelo,
    required this.fechaEntrada,
    required this.tiempoEsperado,
  });

  factory CamionDto.fromJson(Map<String, dynamic> json) {
    return CamionDto(
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

  CamionModel toModel() {
    return CamionModel(
      idCamion: idCamion,
      clienteId: clienteId,
      placas: placas,
      marca: marca,
      modelo: modelo,
      fechaEntrada: fechaEntrada,
      tiempoEsperado: tiempoEsperado,
    );
  }

  factory CamionDto.fromModel(CamionModel model) {
    return CamionDto(
      idCamion: model.idCamion,
      clienteId: model.clienteId,
      placas: model.placas,
      marca: model.marca,
      modelo: model.modelo,
      fechaEntrada: model.fechaEntrada,
      tiempoEsperado: model.tiempoEsperado,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateCamionDto {
  final int clienteId;
  final String placas;
  final String? marca;
  final String? modelo;
  final DateTime fechaEntrada;
  final DateTime tiempoEsperado;

  const CreateCamionDto({
    required this.clienteId,
    required this.placas,
    this.marca,
    this.modelo,
    required this.fechaEntrada,
    required this.tiempoEsperado,
  });

  factory CreateCamionDto.fromJson(Map<String, dynamic> json) {
    return CreateCamionDto(
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
      'cliente_id': clienteId,
      'placas': placas,
      'marca': marca,
      'modelo': modelo,
      'fechaEntrada': fechaEntrada.toIso8601String(),
      'tiempoEsperado': tiempoEsperado.toIso8601String(),
    };
  }
}
