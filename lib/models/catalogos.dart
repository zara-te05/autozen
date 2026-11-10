/// Usuario del sistema (tabla USUARIO del backend).
class UsuarioSistema {
  final int id;
  String nombre;
  String username;
  String rol;
  String puesto;
  String contacto;

  /// Proyectos, Compras, Almacen o Evaluacion. Null para el Admin.
  String? area;

  UsuarioSistema({
    required this.id,
    required this.nombre,
    required this.username,
    required this.rol,
    this.puesto = '',
    this.contacto = '',
    this.area,
  });

  factory UsuarioSistema.fromJson(Map<String, dynamic> j) => UsuarioSistema(
        id: (j['idUsuario'] as num).toInt(),
        nombre: j['nombre'] as String? ?? '',
        username: j['username'] as String? ?? '',
        rol: j['rol'] as String? ?? 'Usuario',
        puesto: j['puestoTrabajo'] as String? ?? '',
        contacto: j['metodoContacto'] as String? ?? '',
        area: j['area'] as String?,
      );
}

/// Roles del backend con su nombre legible.
const Map<String, String> rolesSistema = {
  'Admin': 'Administrador (acceso total)',
  'Proyecto_Lider': 'Jefe de Proyectos',
  'Compras_Admin': 'Jefe de Compras',
  'Almacen_Admin': 'Jefe de Almacén',
  'Evaluacion_Admin': 'Jefe de Evaluación (Recepción)',
  'Usuario': 'Usuario (solo lectura de su área)',
};

/// Áreas del taller (mismos valores que el backend) con su nombre legible.
const Map<String, String> areasSistema = {
  'Proyectos': 'Proyectos',
  'Compras': 'Compras',
  'Almacen': 'Almacén',
  'Evaluacion': 'Evaluación',
};

/// Área de un rol de jefe; null para Admin y Usuario.
String? areaDeRol(String rol) => switch (rol) {
      'Proyecto_Lider' => 'Proyectos',
      'Compras_Admin' => 'Compras',
      'Almacen_Admin' => 'Almacen',
      'Evaluacion_Admin' => 'Evaluacion',
      _ => null,
    };

bool esRolJefe(String rol) => areaDeRol(rol) != null;

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
