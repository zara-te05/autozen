/// Modelo de dominio para TrabajadorModel.
class TrabajadorModel {
  final int? idTrabajador;
  final String nombreTrabajador;
  final String apellidoTrabajador;
  final double? salarioTrabajador;

  const TrabajadorModel({
    this.idTrabajador,
    required this.nombreTrabajador,
    required this.apellidoTrabajador,
    this.salarioTrabajador,
  });

  factory TrabajadorModel.fromJson(Map<String, dynamic> json) {
    return TrabajadorModel(
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

  TrabajadorModel copyWith({
    int? idTrabajador,
    String? nombreTrabajador,
    String? apellidoTrabajador,
    double? salarioTrabajador,
  }) {
    return TrabajadorModel(
      idTrabajador: idTrabajador ?? this.idTrabajador,
      nombreTrabajador: nombreTrabajador ?? this.nombreTrabajador,
      apellidoTrabajador: apellidoTrabajador ?? this.apellidoTrabajador,
      salarioTrabajador: salarioTrabajador ?? this.salarioTrabajador,
    );
  }
}
