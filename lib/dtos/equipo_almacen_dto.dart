import '../models/equipo_almacen_model.dart';

/// DTO para transferir datos completos o respuestas de API para EquipoAlmacenModel.
class EquipoAlmacenDto {
  final int? idEquipo;
  final int operacionId;
  final int? trabajadorId;
  final String nombreHerramienta;
  final String? estadoSalida;
  final String? estadoDevuelto;

  const EquipoAlmacenDto({
    this.idEquipo,
    required this.operacionId,
    this.trabajadorId,
    required this.nombreHerramienta,
    this.estadoSalida,
    this.estadoDevuelto,
  });

  factory EquipoAlmacenDto.fromJson(Map<String, dynamic> json) {
    return EquipoAlmacenDto(
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

  EquipoAlmacenModel toModel() {
    return EquipoAlmacenModel(
      idEquipo: idEquipo,
      operacionId: operacionId,
      trabajadorId: trabajadorId,
      nombreHerramienta: nombreHerramienta,
      estadoSalida: estadoSalida,
      estadoDevuelto: estadoDevuelto,
    );
  }

  factory EquipoAlmacenDto.fromModel(EquipoAlmacenModel model) {
    return EquipoAlmacenDto(
      idEquipo: model.idEquipo,
      operacionId: model.operacionId,
      trabajadorId: model.trabajadorId,
      nombreHerramienta: model.nombreHerramienta,
      estadoSalida: model.estadoSalida,
      estadoDevuelto: model.estadoDevuelto,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateEquipoAlmacenDto {
  final int operacionId;
  final int? trabajadorId;
  final String nombreHerramienta;
  final String? estadoSalida;
  final String? estadoDevuelto;

  const CreateEquipoAlmacenDto({
    required this.operacionId,
    this.trabajadorId,
    required this.nombreHerramienta,
    this.estadoSalida,
    this.estadoDevuelto,
  });

  factory CreateEquipoAlmacenDto.fromJson(Map<String, dynamic> json) {
    return CreateEquipoAlmacenDto(
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      trabajadorId: (json['trabajador_id'] ?? json['trabajadorId']) != null ? ((json['trabajador_id'] ?? json['trabajadorId']) as num).toInt() : null,
      nombreHerramienta: ((json['nombreHerramienta'] ?? json['nombre_herramienta']) ?? '').toString(),
      estadoSalida: (json['estadoSalida'] ?? json['estado_salida']) as String?,
      estadoDevuelto: (json['estadoDevuelto'] ?? json['estado_devuelto']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operacion_id': operacionId,
      'trabajador_id': trabajadorId,
      'nombreHerramienta': nombreHerramienta,
      'estadoSalida': estadoSalida,
      'estadoDevuelto': estadoDevuelto,
    };
  }
}
