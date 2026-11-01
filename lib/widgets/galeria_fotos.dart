import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/fotos_service.dart';
import '../utils/app_theme.dart';

/// Cuadrícula de fotos con botones para tomar/agregar y quitar. Al tocar una foto se abre en grande.
class GaleriaFotos extends StatefulWidget {
  final List<String> fotos;
  final ValueChanged<String> onAgregada;
  final ValueChanged<String>? onQuitada;
  final bool editable;

  const GaleriaFotos({
    super.key,
    required this.fotos,
    required this.onAgregada,
    this.onQuitada,
    this.editable = true,
  });

  @override
  State<GaleriaFotos> createState() => _GaleriaFotosState();
}

class _GaleriaFotosState extends State<GaleriaFotos> {
  bool _cargando = false;

  Future<void> _obtener({required bool desdeCamara}) async {
    setState(() => _cargando = true);
    try {
      final ruta = await FotosService.obtenerFoto(desdeCamara: desdeCamara);
      if (ruta != null) widget.onAgregada(ruta);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la foto: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _verEnGrande(String ruta) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, title: const Text('Foto')),
          body: Center(
            child: InteractiveViewer(
              maxScale: 5,
              child: _imagen(ruta, oscuro: true),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool camara = FotosService.camaraDisponible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.fotos.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.inputFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.photo_library_outlined, size: 36, color: AppTheme.textMuted),
                SizedBox(height: 6),
                Text('Sin fotos todavía', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          )
        else
          GridView.extent(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            maxCrossAxisExtent: 140,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final ruta in widget.fotos)
                Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        color: AppTheme.inputFill,
                        child: InkWell(
                          onTap: () => _verEnGrande(ruta),
                          child: _imagen(ruta, miniatura: true),
                        ),
                      ),
                    ),
                    if (widget.editable && widget.onQuitada != null)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => widget.onQuitada!(ruta),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        if (widget.editable) ...[
          const SizedBox(height: 12),
          if (_cargando)
            const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (camara)
                  ElevatedButton.icon(
                    onPressed: () => _obtener(desdeCamara: true),
                    icon: const Icon(Icons.photo_camera_outlined, color: Colors.white, size: 18),
                    label: const Text('Tomar foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _obtener(desdeCamara: false),
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 18),
                  label: Text(
                    camara ? 'Elegir de la galería' : 'Agregar foto desde archivo',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  /// Foto local (ruta del dispositivo) o del servidor (URL "/api/..." protegida con el token).
  Widget _imagen(String ruta, {bool miniatura = false, bool oscuro = false}) {
    final remota = ruta.startsWith('/api/') || ruta.startsWith('http');
    Widget error(BuildContext context, Object e, StackTrace? s) => _fotoNoDisponible(oscuro: oscuro);
    if (remota) {
      return Image.network(
        ApiClient.urlAbsoluta(ruta),
        headers: ApiClient.headersAutorizacion,
        fit: miniatura ? BoxFit.cover : null,
        cacheWidth: miniatura ? 400 : null,
        errorBuilder: error,
        loadingBuilder: (context, child, progreso) =>
            progreso == null ? child : const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    return Image.file(File(ruta), fit: miniatura ? BoxFit.cover : null, cacheWidth: miniatura ? 400 : null, errorBuilder: error);
  }

  Widget _fotoNoDisponible({bool oscuro = false}) {
    return Center(
      child: Icon(Icons.broken_image_outlined, color: oscuro ? Colors.white54 : AppTheme.textMuted),
    );
  }
}
