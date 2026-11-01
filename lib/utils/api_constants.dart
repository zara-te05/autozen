import 'dart:io';
import 'package:flutter/foundation.dart';

/// Dirección del backend .NET.
///
/// Por defecto apunta a la PC de desarrollo (puerto 5102 de `dotnet run`):
/// - Emulador de Android: 10.0.2.2 es el localhost de la PC.
/// - Windows: localhost.
/// Para un teléfono físico o un servidor, pásala al compilar:
///   flutter run --dart-define=API_URL=http://192.168.1.50:5102/api
class ApiConstants {
  static const String _definida = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_definida.isNotEmpty) return _definida;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5102/api';
    return 'http://localhost:5102/api';
  }

  /// Raíz del servidor (sin /api), para URLs que el backend devuelve como "/api/...".
  static String get servidor => baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;
}
