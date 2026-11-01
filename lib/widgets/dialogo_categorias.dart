import 'package:flutter/material.dart';
import '../services/almacen_store.dart';
import '../utils/app_theme.dart';
import 'confirm_dialog.dart';

/// Ventana para crear, renombrar y eliminar las categorías del almacén.
Future<void> mostrarDialogoCategorias(BuildContext context) {
  return showDialog(context: context, builder: (context) => const _DialogoCategorias());
}

class _DialogoCategorias extends StatefulWidget {
  const _DialogoCategorias();

  @override
  State<_DialogoCategorias> createState() => _DialogoCategoriasState();
}

class _DialogoCategoriasState extends State<_DialogoCategorias> {
  final AlmacenStore _store = AlmacenStore.instancia;
  final TextEditingController _nueva = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nueva.dispose();
    super.dispose();
  }

  Future<void> _agregar() async {
    final error = await _store.agregarCategoria(_nueva.text);
    if (!mounted) return;
    setState(() => _error = error);
    if (error == null) _nueva.clear();
  }

  Future<void> _renombrar(String actual) async {
    final ctrl = TextEditingController(text: actual);
    final nuevo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar categoría'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: AppTheme.inputDecoration('Nombre de la categoría'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Guardar')),
        ],
      ),
    );
    ctrl.dispose();
    if (nuevo == null) return;
    final error = await _store.renombrarCategoria(actual, nuevo);
    if (mounted) setState(() => _error = error);
  }

  Future<void> _eliminar(String categoria) async {
    final enUso = _store.articulosEnCategoria(categoria);
    if (enUso > 0) {
      final error = await _store.eliminarCategoria(categoria);
      if (mounted) setState(() => _error = error);
      return;
    }
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar categoría',
      message: '¿Eliminar la categoría "$categoria"?',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirmar) return;
    final error = await _store.eliminarCategoria(categoria);
    if (mounted) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Categorías del almacén', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 420,
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final categorias = _store.categorias;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nueva,
                        decoration: AppTheme.inputDecoration('Nueva categoría', icon: Icons.add),
                        onSubmitted: (_) => _agregar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _agregar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Agregar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 12),
                Flexible(
                  child: categorias.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No hay categorías. Agrega la primera.', style: TextStyle(color: AppTheme.textSecondary)),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: categorias.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final c = categorias[i];
                            final enUso = _store.articulosEnCategoria(c);
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('$enUso artículo(s)'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Renombrar', onPressed: () => _renombrar(c)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                                    tooltip: 'Eliminar',
                                    onPressed: () => _eliminar(c),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }
}
