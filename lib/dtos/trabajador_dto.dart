import '../models/trabajador_model.dart';

/// DTO para transferir datos completos o respuestas de API para TrabajadorModel.
class TrabajadorDto {
  final int? idTrabajador;
  final String nombreTrabajador;
  final String apellidoTrabajador;
  final double? salarioTrabajador;

  const TrabajadorDto({
    this.idTrabajador,
    required this.nombreTrabajador,
    required this.apellidoTrabajador,
    this.salarioTrabajador,
  });

  factory TrabajadorDto.fromJson(Map<String, dynamic> json) {
    return TrabajadorDto(
      idTrabajador: (json['id_trabajador'] ?? json['idTrabajador']) != null ? ((json['id_trabajador'] ?? json['idTrabajador']) as num).toInt() : null,
      nombreTrabajador: ((json['nombreTrabajador'] ?? json['nombre_trabajador']) ?? '').toString(),
      apellidoTrabajador: ((json['apellidoTrabajador'] ?? json['apellido_trabajador']) ?? '').toString(),
      salarioTrabajador: (json['salarioTrabajador'] ?? json['salario_trabajador']) != null ? ((json['salarioTrabajador'] ?? json['salario_trabajador']) as num).toDouble() : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (idTrabajador != null) 'id_trabajador': idTrabajador,
      'nombreTrabajador': nombreTrabajador,
      'apellidoTrabajador': apellidoTrabajador,
      'salarioTrabajador': salarioTrabajador,
    };
  }

  TrabajadorModel toModel() {
    return TrabajadorModel(
      idTrabajador: idTrabajador,
      nombreTrabajador: nombreTrabajador,
      apellidoTrabajador: apellidoTrabajador,
      salarioTrabajador: salarioTrabajador,
    );
  }

  factory TrabajadorDto.fromModel(TrabajadorModel model) {
    return TrabajadorDto(
      idTrabajador: model.idTrabajador,
      nombreTrabajador: model.nombreTrabajador,
      apellidoTrabajador: model.apellidoTrabajador,
      salarioTrabajador: model.salarioTrabajador,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateTrabajadorDto {
  final String nombreTrabajador;
  final String apellidoTrabajador;
  final double? salarioTrabajador;

  const CreateTrabajadorDto({
    required this.nombreTrabajador,
    required this.apellidoTrabajador,
    this.salarioTrabajador,
  });

  factory CreateTrabajadorDto.fromJson(Map<String, dynamic> json) {
    return CreateTrabajadorDto(
      nombreTrabajador: ((json['nombreTrabajador'] ?? json['nombre_trabajador']) ?? '').toString(),
      apellidoTrabajador: ((json['apellidoTrabajador'] ?? json['apellido_trabajador']) ?? '').toString(),
      salarioTrabajador: (json['salarioTrabajador'] ?? json['salario_trabajador']) != null ? ((json['salarioTrabajador'] ?? json['salario_trabajador']) as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreTrabajador': nombreTrabajador,
      'apellidoTrabajador': apellidoTrabajador,
      'salarioTrabajador': salarioTrabajador,
    };
  }
}
