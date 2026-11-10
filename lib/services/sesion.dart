import 'package:flutter/foundation.dart';
import '../models/catalogos.dart';
import 'almacen_store.dart';
import 'api_client.dart';
import 'avisos_store.dart';
import 'catalogos_store.dart';
import 'compras_store.dart';
import 'proveedores_store.dart';
import 'proyectos_store.dart';
import 'tablero_store.dart';

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

  /// Área del usuario (Proyectos, Compras, Almacen, Evaluacion). Null para el Admin.
  static String? area;

  static bool get esAdmin => rol == 'Admin';

  /// Jefe de departamento (Proyecto_Lider, Compras_Admin, Almacen_Admin, Evaluacion_Admin).
  static bool get esJefe => esRolJefe(rol);

  /// Admin y jefes administran usuarios (los jefes solo los de su área).
  static bool get gestionaUsuarios => esAdmin || esJefe;

  // ---------------------------------------------------------------- Permisos de lectura
  // Admin y jefes leen todas las áreas; un 'Usuario' solo la suya (el backend aplica lo mismo).

  static bool _lee(List<String> areas) => esAdmin || esJefe || (area != null && areas.contains(area));

  /// Proyectos de clientes y de aseguradora (la evaluación de daños vive dentro del proyecto).
  static bool get veProyectos => _lee(const ['Proyectos', 'Evaluacion']);

  /// Evaluación de Daños (captura de proyectos nuevos).
  static bool get veEvaluacion => _lee(const ['Evaluacion']);

  /// Compras y proveedores.
  static bool get veCompras => _lee(const ['Compras']);

  static bool get veAlmacen => _lee(const ['Almacen']);

  // ---------------------------------------------------------------- Permisos de escritura
  // Mismas reglas que el backend (Security/Roles.cs → Edicion). Si no hay permiso, el botón no se muestra.

  static bool _rolEn(List<String> roles) => roles.contains(rol);

  /// Editar proyectos: datos, etapas, avanzar etapa, archivar y restaurar.
  static bool get editaProyectos => _rolEn(const ['Admin', 'Proyecto_Lider']);

  /// Crear proyectos (Evaluación de Daños) y subir o borrar sus fotos y PDFs.
  static bool get creaProyectos => _rolEn(const ['Admin', 'Proyecto_Lider', 'Evaluacion_Admin']);

  /// Aprobar o rechazar solicitudes, órdenes de compra y proveedores.
  static bool get editaCompras => _rolEn(const ['Admin', 'Compras_Admin']);

  /// Solicitar compras para un proyecto.
  static bool get solicitaCompras => _rolEn(const ['Admin', 'Proyecto_Lider', 'Compras_Admin']);

  /// Artículos, categorías y resguardos de almacén.
  static bool get editaAlmacen => _rolEn(const ['Admin', 'Almacen_Admin']);

  /// Vales de material y préstamo o devolución de herramientas.
  static bool get registraVales => _rolEn(const ['Admin', 'Almacen_Admin', 'Proyecto_Lider']);

  /// Texto para la cabecera del dashboard.
  static String get descripcionVista {
    if (esAdmin) return 'Vista de Administrador';
    if (esJefe) return 'Jefe de ${areasSistema[area] ?? area ?? ''}';
    return area == null ? 'Usuario sin área asignada' : 'Usuario de ${areasSistema[area] ?? area}';
  }

  static void iniciarDemo({required String rol}) {
    modoDemo = true;
    Sesion.rol = rol;
    area = areaDeRol(rol);
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
    area = (respuestaLogin['area'] as String?) ?? areaDeRol(rol);
    AvisosStore.instancia.iniciarSondeo();
    return sincronizar();
  }

  /// Vuelve a leer todo del backend.
  static Future<String?> sincronizar() async {
    if (modoDemo) return null;
    // Solo se carga lo que el usuario puede leer: lo demás respondería 403 (y se vacía para no mostrar datos ajenos)
    if (!veProyectos) ProyectosStore.instancia.vaciar();
    if (!veAlmacen) AlmacenStore.instancia.vaciar();
    if (!veCompras) {
      ProveedoresStore.instancia.vaciar();
      ComprasStore.instancia.vaciar();
    }
    final resultados = await Future.wait([
      if (veProyectos) ProyectosStore.instancia.cargar(),
      if (veAlmacen) AlmacenStore.instancia.cargar(),
      if (veCompras) ProveedoresStore.instancia.cargar(),
      if (veCompras) ComprasStore.instancia.cargar(),
      CatalogosStore.instancia.cargar(),
      AvisosStore.instancia.cargar(),
      TableroStore.instancia.cargar(),
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
    area = null;
    reiniciarDatosDemo();
  }

  static void reiniciarDatosDemo() {
    ProyectosStore.instancia.reiniciarDemo();
    AlmacenStore.instancia.reiniciarDemo();
    ProveedoresStore.instancia.reiniciarDemo();
    ComprasStore.instancia.reiniciarDemo();
    CatalogosStore.instancia.reiniciarDemo();
    AvisosStore.instancia.reiniciarDemo();
    TableroStore.instancia.reiniciarDemo();
  }
}
