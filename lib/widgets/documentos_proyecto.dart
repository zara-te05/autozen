import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../models/proyecto_taller.dart';
import '../services/api_client.dart';
import '../services/proyectos_store.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import 'confirm_dialog.dart';

/// PDFs que manda la aseguradora (autorización, póliza, valuación...). Solo en proyectos de aseguradora.
class DocumentosProyecto extends StatefulWidget {
  final ProyectoTaller proyecto;

  const DocumentosProyecto({super.key, required this.proyecto});

  @override
  State<DocumentosProyecto> createState() => _DocumentosProyectoState();
}

class _DocumentosProyectoState extends State<DocumentosProyecto> {
  final ProyectosStore _store = ProyectosStore.instancia;
  bool _ocupado = false;

  ProyectoTaller get _p => widget.proyecto;

  static const XTypeGroup _pdf = XTypeGroup(
    label: 'PDF',
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
    uniformTypeIdentifiers: ['com.adobe.pdf'],
  );

  void _mensaje(String texto, {bool error = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: error ? AppTheme.danger : AppTheme.success),
    );
  }

  Future<void> _subir() async {
    final archivo = await openFile(acceptedTypeGroups: const [_pdf]);
    if (archivo == null) return;
    setState(() => _ocupado = true);
    try {
      final error = await _store.agregarDocumento(_p, ruta: archivo.path, nombre: archivo.name, tamano: await archivo.length());
      _mensaje(error ?? 'PDF "${archivo.name}" agregado.', error: error != null);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _abrir(DocumentoProyecto doc) async {
    setState(() => _ocupado = true);
    try {
      var ruta = doc.ruta;
      if (doc.remoto) {
        // Se descarga con el token a una carpeta temporal y se abre con el visor del sistema
        final bytes = await ApiClient().descargar(doc.ruta);
        final temporal = await getTemporaryDirectory();
        final archivo = File('${temporal.path}${Platform.pathSeparator}${doc.id ?? DateTime.now().millisecondsSinceEpoch}_${doc.nombre}');
        await archivo.writeAsBytes(bytes, flush: true);
        ruta = archivo.path;
      }
      final resultado = await OpenFilex.open(ruta, type: 'application/pdf');
      if (resultado.type != ResultType.done) _mensaje('No se pudo abrir el PDF: ${resultado.message}');
    } on ApiException catch (e) {
      _mensaje(e.mensaje);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _quitar(DocumentoProyecto doc) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar PDF',
      message: '¿Eliminar "${doc.nombre}" del proyecto?',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirmar) return;
    final error = await _store.quitarDocumento(_p, doc);
    if (error != null) _mensaje(error);
  }

  static String _tamano(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final docs = _p.documentos;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Documentos de la aseguradora (PDF)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
              Text('${docs.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          if (docs.isEmpty)
            const Text('Aún no se ha subido ningún PDF (autorización, póliza, valuación...).',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
          else
            for (final d in docs)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.border)),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.picture_as_pdf, color: AppTheme.danger),
                  title: Text(d.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text([_tamano(d.tamano), formatearFecha(d.fecha)].where((t) => t.isNotEmpty).join(' • ')),
                  onTap: _ocupado ? null : () => _abrir(d),
                  trailing: _p.archivado
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
                          tooltip: 'Eliminar',
                          onPressed: () => _quitar(d),
                        ),
                ),
              ),
          if (!_p.archivado) ...[
            const SizedBox(height: 6),
            _ocupado
                ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                : OutlinedButton.icon(
                    onPressed: _subir,
                    icon: const Icon(Icons.upload_file, color: AppTheme.primary),
                    label: const Text('Subir PDF de la aseguradora', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.border)),
                  ),
          ],
        ],
      ),
    );
  }
}
