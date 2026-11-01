import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Toma o elige fotos y las copia a la carpeta de documentos de la app, para que no se pierdan
/// cuando el sistema limpie los archivos temporales.
class FotosService {
  FotosService._();

  static final ImagePicker _picker = ImagePicker();

  /// image_picker abre la cámara en Android e iOS. En Windows la cámara no está soportada
  /// de fábrica, así que ahí solo se ofrece elegir un archivo.
  static bool get camaraDisponible => Platform.isAndroid || Platform.isIOS;

  /// Devuelve la ruta de la foto guardada, o null si el usuario canceló.
  static Future<String?> obtenerFoto({required bool desdeCamara}) async {
    final XFile? foto = await _picker.pickImage(
      source: desdeCamara ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (foto == null) return null;

    final documentos = await getApplicationDocumentsDirectory();
    final carpeta = Directory('${documentos.path}${Platform.pathSeparator}autozen_fotos');
    if (!await carpeta.exists()) await carpeta.create(recursive: true);

    final punto = foto.name.lastIndexOf('.');
    final extension = punto >= 0 ? foto.name.substring(punto) : '.jpg';
    final destino = '${carpeta.path}${Platform.pathSeparator}foto_${DateTime.now().millisecondsSinceEpoch}$extension';
    await foto.saveTo(destino);
    return destino;
  }

  /// Borra el archivo de una foto descartada. Ignora errores (el archivo pudo no existir).
  static Future<void> borrar(String ruta) async {
    try {
      final archivo = File(ruta);
      if (await archivo.exists()) await archivo.delete();
    } catch (_) {}
  }
}
