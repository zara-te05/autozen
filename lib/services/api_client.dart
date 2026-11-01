import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/api_constants.dart';

/// Error de la API con un mensaje listo para mostrarse al usuario.
class ApiException implements Exception {
  final int status;
  final String mensaje;

  const ApiException(this.status, this.mensaje);

  bool get sinConexion => status == 0;

  @override
  String toString() => mensaje;
}

/// Cliente HTTP centralizado para el backend .NET.
class ApiClient {
  /// Token JWT de la sesión actual. Lo asigna [login].
  static String? token;

  /// Rol devuelto por el backend (Admin, Proyecto_Lider, Compras_Admin, ...).
  static String? rol;

  static const Duration _tiempoMaximo = Duration(seconds: 20);

  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  /// Encabezado de autorización, también para cargar imágenes protegidas con Image.network.
  static Map<String, String> get headersAutorizacion => {if (token != null) 'Authorization': 'Bearer $token'};

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headersAutorizacion,
      };

  /// Convierte "/api/Proyecto/3/fotos/7" en una URL completa del servidor.
  static String urlAbsoluta(String ruta) => ruta.startsWith('http') ? ruta : '${ApiConstants.servidor}$ruta';

  Uri _uri(String endpoint) => Uri.parse('${ApiConstants.baseUrl}$endpoint');

  Future<dynamic> get(String endpoint) => _enviar(() => _client.get(_uri(endpoint), headers: _headers));

  Future<dynamic> post(String endpoint, [Object? body]) =>
      _enviar(() => _client.post(_uri(endpoint), headers: _headers, body: body == null ? null : jsonEncode(body)));

  Future<dynamic> put(String endpoint, Object body) =>
      _enviar(() => _client.put(_uri(endpoint), headers: _headers, body: jsonEncode(body)));

  Future<dynamic> delete(String endpoint) => _enviar(() => _client.delete(_uri(endpoint), headers: _headers));

  /// Sube un archivo como multipart/form-data.
  Future<dynamic> subirArchivo(String endpoint, String rutaArchivo, {String campo = 'archivo', String? nombreArchivo}) {
    return _enviar(() async {
      final request = http.MultipartRequest('POST', _uri(endpoint))
        ..headers.addAll(headersAutorizacion)
        ..files.add(await http.MultipartFile.fromPath(
          campo,
          rutaArchivo,
          filename: nombreArchivo,
          contentType: _tipoContenido(nombreArchivo ?? rutaArchivo),
        ));
      return http.Response.fromStream(await _client.send(request));
    });
  }

  /// Descarga un archivo protegido (p. ej. un PDF) y devuelve sus bytes.
  Future<List<int>> descargar(String ruta) async {
    final http.Response response;
    try {
      response = await _client.get(Uri.parse(urlAbsoluta(ruta)), headers: headersAutorizacion).timeout(const Duration(minutes: 2));
    } on SocketException {
      throw const ApiException(0, 'No se pudo conectar con el servidor.');
    } on TimeoutException {
      throw const ApiException(0, 'La descarga tardó demasiado.');
    }
    if (response.statusCode != 200) throw ApiException(response.statusCode, _mensajeDeError(response));
    return response.bodyBytes;
  }

  /// Inicia sesión contra POST /api/Auth/login y guarda el token y el rol.
  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = Map<String, dynamic>.from(await post('/Auth/login', {'username': username, 'password': password}) as Map);
    token = data['token'] as String?;
    rol = data['rol'] as String?;
    return data;
  }

  static void logout() {
    token = null;
    rol = null;
  }

  Future<dynamic> _enviar(Future<http.Response> Function() peticion) async {
    final http.Response response;
    try {
      response = await peticion().timeout(_tiempoMaximo);
    } on SocketException {
      throw const ApiException(0, 'No se pudo conectar con el servidor. Revisa tu conexión.');
    } on TimeoutException {
      throw const ApiException(0, 'El servidor tardó demasiado en responder.');
    } on http.ClientException {
      throw const ApiException(0, 'No se pudo conectar con el servidor.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw ApiException(response.statusCode, _mensajeDeError(response));
  }

  /// Extrae el mensaje de un ProblemDetails (detail, title o errores de validación).
  static String _mensajeDeError(http.Response response) {
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is Map) {
        final errores = json['errors'];
        if (errores is Map && errores.isNotEmpty) {
          final primero = errores.values.first;
          if (primero is List && primero.isNotEmpty) return primero.first.toString();
        }
        final detalle = json['detail'] ?? json['title'] ?? json['message'];
        if (detalle != null) return detalle.toString();
      }
    } catch (_) {}
    return switch (response.statusCode) {
      401 => 'Tu sesión expiró. Vuelve a iniciar sesión.',
      403 => 'No tienes permiso para hacer esto.',
      404 => 'No se encontró el registro.',
      429 => 'Demasiados intentos. Espera un minuto.',
      _ => 'Error del servidor (${response.statusCode}).',
    };
  }

  static MediaType _tipoContenido(String ruta) {
    final r = ruta.toLowerCase();
    if (r.endsWith('.pdf')) return MediaType('application', 'pdf');
    if (r.endsWith('.png')) return MediaType('image', 'png');
    if (r.endsWith('.webp')) return MediaType('image', 'webp');
    if (r.endsWith('.heic')) return MediaType('image', 'heic');
    return MediaType('image', 'jpeg');
  }
}
