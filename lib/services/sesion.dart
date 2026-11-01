import 'package:flutter/foundation.dart';
import 'almacen_store.dart';
import 'api_client.dart';
import 'avisos_store.dart';
import 'catalogos_store.dart';
import 'compras_store.dart';
import 'proveedores_store.dart';
import 'proyectos_store.dart';

/// Sesión actual.
///
/// - **Modo demo** (cuentas de prueba, solo en debug): todo vive en memoria con datos de ejemplo.
/// - **Modo API**: los datos se cargan del backend y cada cambio se guarda ahí.
class Sesion {
  Sesion._();

  /// Mientras nadie inicie sesión con una cuenta real, la app trabaja en memoria.
  static bool modoDemo = true;
  static String rol = 'Admin';
  static String nombre = '';

  static bool get esAdmin => rol == 'Admin';

  static void iniciarDemo({required String rol}) {
    modoDemo = true;
    Sesion.rol = rol;
    nombre = switch (rol) {
      'Admin' => 'Administrador (demo)',
      'Proyecto_Lider' => 'Jefe de Proyectos (demo)',
      'Compras_Admin' => 'Jefe de Compras (demo)',
      'Almacen_Admin' => 'Jefe de Almacén (demo)',
      'Evaluacion_Admin' => 'Jefe de Evaluación (demo)',
      _ => 'Usuario (demo)',
    };
    reiniciarDatosDemo();
  }

  /// Llamar después de un login exitoso contra la API. Devuelve un error si no se pudo sincronizar.
  static Future<String?> iniciarConApi(Map<String, dynamic> respuestaLogin) async {
    modoDemo = false;
    rol = respuestaLogin['rol'] as String? ?? 'Usuario';
    nombre = respuestaLogin['nombre'] as String? ?? '';
    AvisosStore.instancia.iniciarSondeo();
    return sincronizar();
  }

  /// Vuelve a leer todo del backend.
  static Future<String?> sincronizar() async {
    if (modoDemo) return null;
    final resultados = await Future.wait([
      ProyectosStore.instancia.cargar(),
      AlmacenStore.instancia.cargar(),
      ProveedoresStore.instancia.cargar(),
      ComprasStore.instancia.cargar(),
      CatalogosStore.instancia.cargar(),
      AvisosStore.instancia.cargar(),
    ]);
    final errores = resultados.whereType<String>().toSet();
    if (errores.isNotEmpty) debugPrint('Errores al sincronizar: $errores');
    return errores.isEmpty ? null : errores.first;
  }

  static void cerrar() {
    ApiClient.logout();
    modoDemo = true;
    rol = 'Admin';
    nombre = '';
    reiniciarDatosDemo();
  }

  static void reiniciarDatosDemo() {
    ProyectosStore.instancia.reiniciarDemo();
    AlmacenStore.instancia.reiniciarDemo();
    ProveedoresStore.instancia.reiniciarDemo();
    ComprasStore.instancia.reiniciarDemo();
    CatalogosStore.instancia.reiniciarDemo();
    AvisosStore.instancia.reiniciarDemo();
  }
}
