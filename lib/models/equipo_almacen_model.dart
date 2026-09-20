/// Modelo de dominio para EquipoAlmacenModel.
class EquipoAlmacenModel {
  final int? idEquipo;
  final int operacionId;
  final int? trabajadorId;
  final String nombreHerramienta;
  final String? estadoSalida;
  final String? estadoDevuelto;

  const EquipoAlmacenModel({
    this.idEquipo,
    required this.operacionId,
    this.trabajadorId,
    required this.nombreHerramienta,
    this.estadoSalida,
    this.estadoDevuelto,
  });

  factory EquipoAlmacenModel.fromJson(Map<String, dynamic> json) {
    return EquipoAlmacenModel(
      idEquipo: (json['id_equipo'] ?? json['idEquipo']) != null ? ((json['id_equipo'] ?? json['idEquipo']) as num).toInt() : null,
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      trabajadorId: (json['trabajador_id'] ?? json['trabajadorId']) != null ? ((json['trabajador_id'] ?? json['trabajadorId']) as num).toInt() : null,
      nombreHerramienta: ((json['nombreHerramienta'] ?? json['nombre_herramienta']) ?? '').toString(),
      estadoSalida: (json['estadoSalida'] ?? json['estado_salida']) as String?,
      estadoDevuelto: (json['estadoDevuelto'] ?? json['estado_devuelto']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idEquipo != null) 'id_equipo': idEquipo,
      'operacion_id': operacionId,
      'trabajador_id': trabajadorId,
      'nombreHerramienta': nombreHerramienta,
      'estadoSalida': estadoSalida,
      'estadoDevuelto': estadoDevuelto,
    };
  }

  EquipoAlmacenModel copyWith({
    int? idEquipo,
    int? operacionId,
    int? trabajadorId,
    String? nombreHerramienta,
    String? estadoSalida,
    String? estadoDevuelto,
  }) {
    return EquipoAlmacenModel(
      idEquipo: idEquipo ?? this.idEquipo,
      operacionId: operacionId ?? this.operacionId,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      nombreHerramienta: nombreHerramienta ?? this.nombreHerramienta,
      estadoSalida: estadoSalida ?? this.estadoSalida,
      estadoDevuelto: estadoDevuelto ?? this.estadoDevuelto,
    );
  }
}
