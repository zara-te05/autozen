/// Dirección del backend .NET.
///
/// Por defecto apunta al servidor de producción en Railway.
/// Para probar contra la API local (`dotnet run`, puerto 5102), pásala al compilar:
///   flutter run --dart-define=API_URL=http://localhost:5102/api      (Windows)
///   flutter run --dart-define=API_URL=http://10.0.2.2:5102/api       (emulador de Android)
class ApiConstants {
  static const String produccion = 'https://autozen-production.up.railway.app/api';

  static const String _definida = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_definida.isNotEmpty) return _definida;
    return produccion;
  }

  /// Raíz del servidor (sin /api), para URLs que el backend devuelve como "/api/...".
  static String get servidor => baseUrl.endsWith('/api') ? baseUrl.substring(0, baseUrl.length - 4) : baseUrl;
}
