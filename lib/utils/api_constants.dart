import 'dart:io';
import 'package:flutter/foundation.dart';

/// Constantes de configuración de la API .NET Backend para AutoZen.
class ApiConstants {
  /// Retorna la URL base adecuada según la plataforma:
  /// - En Android Emulator: 10.0.2.2 apunta al localhost de tu PC.
  /// - En Windows / Web / iOS Simulator: localhost funciona directamente.
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  // Endpoints del backend en .NET
  static const String usuarios = '/usuarios';
  static const String trabajadores = '/trabajadores';
  static const String clientes = '/clientes';
  static const String camiones = '/camiones';
  static const String proveedores = '/proveedores';
  static const String almacen = '/almacen';
  static const String operaciones = '/operaciones';
  static const String cotizaciones = '/cotizaciones';
  static const String detallesCotizacion = '/detalles-cotizacion';
  static const String solicitudesAlmacen = '/solicitudes-almacen';
  static const String equiposAlmacen = '/equipos-almacen';
  static const String solicitudesCompra = '/solicitudes-compra';
  static const String compras = '/compras';
  static const String devolucionesProveedor = '/devoluciones-proveedor';
  static const String movimientosAlmacen = '/movimientos-almacen';
  static const String facturas = '/facturas';
  static const String valesSalida = '/vales-salida';
}
