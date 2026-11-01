import 'package:flutter/foundation.dart';
import '../models/proveedor.dart';
import 'api_client.dart';
import 'sesion.dart';

/// Catálogo de proveedores compartido (Proveedores y Compras). Con sesión real usa /api/Proveedor.
class ProveedoresStore extends ChangeNotifier {
  ProveedoresStore._() {
    _cargarEjemplos();
  }

  static final ProveedoresStore instancia = ProveedoresStore._();

  final ApiClient _api = ApiClient();
  final List<Proveedor> _proveedores = [];
  int _consecutivo = 0;

  List<Proveedor> get proveedores => List.unmodifiable(_proveedores);

  String siguienteId() => 'PRV-${(_consecutivo + 1).toString().padLeft(3, '0')}';

  Future<String?> cargar() async {
    try {
      final datos = await _api.get('/Proveedor') as List;
      _proveedores
        ..clear()
        ..addAll(datos.map((j) => Proveedor.fromJson(Map<String, dynamic>.from(j as Map))));
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  void reiniciarDemo() {
    _proveedores.clear();
    _cargarEjemplos();
    notifyListeners();
  }

  /// Crea (si [existente] es null) o actualiza un proveedor. Devuelve un mensaje de error, o null si se guardó.
  Future<String?> guardar({
    Proveedor? existente,
    required String nombre,
    required String contacto,
    required int tiempoEntregaDias,
    String direccion = '',
    double? precioPromedio,
  }) async {
    if (_nombreRepetido(nombre, excepto: existente)) return 'Ya existe un proveedor llamado "$nombre".';

    final datos = Proveedor(
      id: existente?.id ?? siguienteId(),
      nombre: nombre,
      contacto: contacto,
      direccion: direccion,
      tiempoEntregaDias: tiempoEntregaDias,
      precioPromedio: precioPromedio,
    );

    if (!Sesion.modoDemo) {
      try {
        if (existente == null) {
          await _api.post('/Proveedor', datos.toJson());
        } else {
          await _api.put('/Proveedor/${existente.serverId}', datos.toJson());
        }
      } on ApiException catch (e) {
        return e.mensaje;
      }
      return cargar();
    }

    if (existente == null) {
      _consecutivo++;
      _proveedores.add(datos..serverId = _consecutivo);
    } else {
      existente
        ..nombre = nombre
        ..contacto = contacto
        ..direccion = direccion
        ..tiempoEntregaDias = tiempoEntregaDias
        ..precioPromedio = precioPromedio;
    }
    notifyListeners();
    return null;
  }

  Future<String?> eliminar(Proveedor proveedor) async {
    if (!Sesion.modoDemo) {
      try {
        await _api.delete('/Proveedor/${proveedor.serverId}');
      } on ApiException catch (e) {
        return e.status == 409 ? 'No se puede eliminar: el proveedor tiene compras registradas.' : e.mensaje;
      }
      return cargar();
    }
    _proveedores.remove(proveedor);
    notifyListeners();
    return null;
  }

  bool _nombreRepetido(String nombre, {Proveedor? excepto}) {
    return _proveedores.any((p) => !identical(p, excepto) && p.nombre.trim().toLowerCase() == nombre.trim().toLowerCase());
  }

  void _cargarEjemplos() {
    _proveedores.addAll([
      Proveedor(id: 'PRV-001', serverId: 1, nombre: 'Refacciones Diésel del Norte', contacto: '871 555 1020', direccion: 'Blvd. Miguel Alemán 1450, Gómez Palacio, Dgo.', tiempoEntregaDias: 3),
      Proveedor(id: 'PRV-002', serverId: 2, nombre: 'Frenos y Balatas de México', contacto: 'ventas@frenosmx.com', tiempoEntregaDias: 4),
      Proveedor(id: 'PRV-003', serverId: 3, nombre: 'Aceites y Lubricantes Industriales', contacto: '871 555 8890', tiempoEntregaDias: 2),
      Proveedor(id: 'PRV-004', serverId: 4, nombre: 'Tornillería y Autopartes del Bajío', contacto: '477 555 3011', tiempoEntregaDias: 5),
    ]);
    _consecutivo = _proveedores.length;
  }
}
