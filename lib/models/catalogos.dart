/// Usuario del sistema (tabla USUARIO del backend).
class UsuarioSistema {
  final int id;
  String nombre;
  String username;
  String rol;
  String puesto;
  String contacto;

  UsuarioSistema({
    required this.id,
    required this.nombre,
    required this.username,
    required this.rol,
    this.puesto = '',
    this.contacto = '',
  });

  factory UsuarioSistema.fromJson(Map<String, dynamic> j) => UsuarioSistema(
        id: (j['idUsuario'] as num).toInt(),
        nombre: j['nombre'] as String? ?? '',
        username: j['username'] as String? ?? '',
        rol: j['rol'] as String? ?? 'Usuario',
        puesto: j['puestoTrabajo'] as String? ?? '',
        contacto: j['metodoContacto'] as String? ?? '',
      );
}

/// Roles del backend con su nombre legible.
const Map<String, String> rolesSistema = {
  'Admin': 'Administrador (acceso total)',
  'Proyecto_Lider': 'Jefe de Proyectos',
  'Compras_Admin': 'Jefe de Compras',
  'Almacen_Admin': 'Jefe de Almacén',
  'Evaluacion_Admin': 'Jefe de Evaluación (Recepción)',
  'Usuario': 'Usuario (solo lectura)',
};

/// Área operativa del taller.
class Departamento {
  final int id;
  String nombre;
  String encargado;
  String icono;
  int personal;

  Departamento({required this.id, required this.nombre, this.encargado = '', this.icono = 'business', this.personal = 0});

  factory Departamento.fromJson(Map<String, dynamic> j) => Departamento(
        id: (j['id'] as num).toInt(),
        nombre: j['nombre'] as String? ?? '',
        encargado: j['encargado'] as String? ?? '',
        icono: j['icono'] as String? ?? 'business',
        personal: (j['personal'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {'nombre': nombre, 'encargado': encargado, 'icono': icono, 'personal': personal};
}
