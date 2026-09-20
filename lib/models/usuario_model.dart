/// Modelo de dominio para UsuarioModel.
class UsuarioModel {
  final int? idUsuario;
  final String nombre;
  final String rol;
  final String? puestoTrabajo;
  final String? metodoContacto;

  const UsuarioModel({
    this.idUsuario,
    required this.nombre,
    required this.rol,
    this.puestoTrabajo,
    this.metodoContacto,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
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

  UsuarioModel copyWith({
    int? idUsuario,
    String? nombre,
    String? rol,
    String? puestoTrabajo,
    String? metodoContacto,
  }) {
    return UsuarioModel(
      idUsuario: idUsuario ?? this.idUsuario,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      puestoTrabajo: puestoTrabajo ?? this.puestoTrabajo,
      metodoContacto: metodoContacto ?? this.metodoContacto,
    );
  }
}
