import '../models/usuario_model.dart';

/// DTO para transferir datos completos o respuestas de API para UsuarioModel.
class UsuarioDto {
  final int? idUsuario;
  final String nombre;
  final String rol;
  final String? puestoTrabajo;
  final String? metodoContacto;

  const UsuarioDto({
    this.idUsuario,
    required this.nombre,
    required this.rol,
    this.puestoTrabajo,
    this.metodoContacto,
  });

  factory UsuarioDto.fromJson(Map<String, dynamic> json) {
    return UsuarioDto(
      idUsuario: (json['id_usuario'] ?? json['idUsuario']) != null ? ((json['id_usuario'] ?? json['idUsuario']) as num).toInt() : null,
      nombre: ((json['nombre']) ?? '').toString(),
      rol: ((json['rol']) ?? '').toString(),
      puestoTrabajo: (json['puestoTrabajo'] ?? json['puesto_trabajo']) as String?,
      metodoContacto: (json['metodoContacto'] ?? json['metodo_contacto']) as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (idUsuario != null) 'id_usuario': idUsuario,
      'nombre': nombre,
      'rol': rol,
      'puestoTrabajo': puestoTrabajo,
      'metodoContacto': metodoContacto,
    };
  }

  UsuarioModel toModel() {
    return UsuarioModel(
      idUsuario: idUsuario,
      nombre: nombre,
      rol: rol,
      puestoTrabajo: puestoTrabajo,
      metodoContacto: metodoContacto,
    );
  }

  factory UsuarioDto.fromModel(UsuarioModel model) {
    return UsuarioDto(
      idUsuario: model.idUsuario,
      nombre: model.nombre,
      rol: model.rol,
      puestoTrabajo: model.puestoTrabajo,
      metodoContacto: model.metodoContacto,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateUsuarioDto {
  final String nombre;
  final String rol;
  final String? puestoTrabajo;
  final String? metodoContacto;

  const CreateUsuarioDto({
    required this.nombre,
    required this.rol,
    this.puestoTrabajo,
    this.metodoContacto,
  });

  factory CreateUsuarioDto.fromJson(Map<String, dynamic> json) {
    return CreateUsuarioDto(
      nombre: ((json['nombre']) ?? '').toString(),
      rol: ((json['rol']) ?? '').toString(),
      puestoTrabajo: (json['puestoTrabajo'] ?? json['puesto_trabajo']) as String?,
      metodoContacto: (json['metodoContacto'] ?? json['metodo_contacto']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'rol': rol,
      'puestoTrabajo': puestoTrabajo,
      'metodoContacto': metodoContacto,
    };
  }
}
