import 'package:flutter/foundation.dart';
import '../models/catalogos.dart';
import 'api_client.dart';
import 'sesion.dart';

/// Usuarios del sistema y departamentos. Con sesión real usa /api/Usuario y /api/Departamento.
class CatalogosStore extends ChangeNotifier {
  CatalogosStore._() {
    _cargarEjemplos();
  }

  static final CatalogosStore instancia = CatalogosStore._();

  final ApiClient _api = ApiClient();
  final List<UsuarioSistema> _usuarios = [];
  final List<Departamento> _departamentos = [];

  List<UsuarioSistema> get usuarios => List.unmodifiable(_usuarios);
  List<Departamento> get departamentos => List.unmodifiable(_departamentos);

  Future<String?> cargar() async {
    try {
      final deptos = await _api.get('/Departamento') as List;
      _departamentos
        ..clear()
        ..addAll(deptos.map((j) => Departamento.fromJson(Map<String, dynamic>.from(j as Map))));
      // La lista de usuarios solo la puede consultar el Admin
      _usuarios.clear();
      if (Sesion.esAdmin) {
        final usuarios = await _api.get('/Usuario') as List;
        _usuarios.addAll(usuarios.map((j) => UsuarioSistema.fromJson(Map<String, dynamic>.from(j as Map))));
      }
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  void reiniciarDemo() {
    _usuarios.clear();
    _departamentos.clear();
    _cargarEjemplos();
    notifyListeners();
  }

  Future<String?> _enApi(Future<dynamic> Function() llamada) async {
    try {
      await llamada();
    } on ApiException catch (e) {
      return e.mensaje;
    }
    return cargar();
  }

  // ---------------------------------------------------------------- Usuarios

  /// Crea (si [existente] es null) o edita un usuario. Al editar, una contraseña vacía conserva la actual.
  Future<String?> guardarUsuario({
    UsuarioSistema? existente,
    required String nombre,
    required String username,
    required String rol,
    required String puesto,
    required String contacto,
    String? password,
  }) async {
    if (nombre.trim().length < 3) return 'Ingresa el nombre completo.';
    if (username.trim().isEmpty) return 'Ingresa el nombre de usuario.';
    if (existente == null && (password == null || password.length < 8)) return 'La contraseña debe tener al menos 8 caracteres.';
    if (existente != null && password != null && password.isNotEmpty && password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    final repetido = _usuarios.any((u) => !identical(u, existente) && u.username.toLowerCase() == username.trim().toLowerCase());
    if (repetido) return 'El usuario "$username" ya existe.';

    if (!Sesion.modoDemo) {
      final cuerpo = {
        'nombre': nombre.trim(),
        'username': username.trim(),
        'rol': rol,
        'puestoTrabajo': puesto.trim(),
        'metodoContacto': contacto.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
      };
      return _enApi(() => existente == null ? _api.post('/Usuario', cuerpo) : _api.put('/Usuario/${existente.id}', cuerpo));
    }

    if (existente == null) {
      final id = _usuarios.isEmpty ? 1 : _usuarios.map((u) => u.id).reduce((a, b) => a > b ? a : b) + 1;
      _usuarios.add(UsuarioSistema(id: id, nombre: nombre.trim(), username: username.trim(), rol: rol, puesto: puesto.trim(), contacto: contacto.trim()));
    } else {
      existente
        ..nombre = nombre.trim()
        ..username = username.trim()
        ..rol = rol
        ..puesto = puesto.trim()
        ..contacto = contacto.trim();
    }
    notifyListeners();
    return null;
  }

  Future<String?> eliminarUsuario(UsuarioSistema usuario) async {
    if (usuario.username.toLowerCase() == 'admin') return 'No se puede eliminar la cuenta principal de administrador.';
    if (!Sesion.modoDemo) return _enApi(() => _api.delete('/Usuario/${usuario.id}'));
    _usuarios.remove(usuario);
    notifyListeners();
    return null;
  }

  // ---------------------------------------------------------------- Departamentos

  Future<String?> guardarDepartamento(Departamento datos, {Departamento? existente}) async {
    if (datos.nombre.trim().isEmpty) return 'Ingresa el nombre del área.';
    if (!Sesion.modoDemo) {
      return _enApi(() => existente == null
          ? _api.post('/Departamento', datos.toJson())
          : _api.put('/Departamento/${existente.id}', datos.toJson()));
    }
    if (existente == null) {
      final id = _departamentos.isEmpty ? 1 : _departamentos.map((d) => d.id).reduce((a, b) => a > b ? a : b) + 1;
      _departamentos.add(Departamento(id: id, nombre: datos.nombre.trim(), encargado: datos.encargado, icono: datos.icono, personal: datos.personal));
    } else {
      existente
        ..nombre = datos.nombre.trim()
        ..encargado = datos.encargado
        ..icono = datos.icono
        ..personal = datos.personal;
    }
    notifyListeners();
    return null;
  }

  Future<String?> eliminarDepartamento(Departamento departamento) async {
    if (!Sesion.modoDemo) return _enApi(() => _api.delete('/Departamento/${departamento.id}'));
    _departamentos.remove(departamento);
    notifyListeners();
    return null;
  }

  void _cargarEjemplos() {
    _usuarios.addAll([
      UsuarioSistema(id: 1, nombre: 'Administrador', username: 'admin', rol: 'Admin', puesto: 'Administración General'),
      UsuarioSistema(id: 2, nombre: 'Gabriela Gómez', username: 'ggomez', rol: 'Almacen_Admin', puesto: 'Almacén'),
      UsuarioSistema(id: 3, nombre: 'Sergio Urey Morales', username: 'surey', rol: 'Proyecto_Lider', puesto: 'Proyectos'),
      UsuarioSistema(id: 4, nombre: 'Laura Ríos', username: 'lrios', rol: 'Evaluacion_Admin', puesto: 'Evaluación (Recepción)'),
    ]);
    _departamentos.addAll([
      Departamento(id: 1, nombre: 'Proyectos', encargado: 'Sergio Urey Morales', icono: 'build', personal: 8),
      Departamento(id: 2, nombre: 'Compras', encargado: 'Carlos Martínez', icono: 'shopping', personal: 2),
      Departamento(id: 3, nombre: 'Almacén', encargado: 'Gabriela Gómez', icono: 'inventory', personal: 3),
      Departamento(id: 4, nombre: 'Evaluación (Recepción)', encargado: 'Laura Ríos', icono: 'fact_check', personal: 2),
    ]);
  }
}
