import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/proveedor.dart';
import '../services/proveedores_store.dart';
import '../services/sesion.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/animaciones.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/menu_lateral.dart';

/// Catálogo de proveedores: alta, edición y eliminación. Compras toma la lista de aquí.
class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final ProveedoresStore _store = ProveedoresStore.instancia;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _abrirFormulario([Proveedor? proveedor]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _FormularioProveedor(proveedor: proveedor),
    );
  }

  Future<void> _eliminar(Proveedor proveedor) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar proveedor',
      message: '¿Eliminar a "${proveedor.nombre}"? Dejará de aparecer al crear órdenes de compra.',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirmar || !mounted) return;
    final error = await _store.eliminar(proveedor);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Proveedor "${proveedor.nombre}" eliminado.'), backgroundColor: AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const MenuLateral(seccion: Seccion.proveedores),
      appBar: AppBar(title: const Text('Proveedores')),
      // Proveedores: solo Compras y el Admin
      floatingActionButton: Sesion.editaCompras
          ? FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              backgroundColor: AppTheme.primary,
              icon: const Icon(Icons.add_business_outlined, color: Colors.white),
              label: const Text('Nuevo proveedor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: ContenidoResponsivo(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final q = _searchQuery.trim().toLowerCase();
            final lista = _store.proveedores
                .where((p) => q.isEmpty || p.nombre.toLowerCase().contains(q) || p.contacto.toLowerCase().contains(q))
                .toList();

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: AppTheme.inputDecoration('Buscar por nombre o contacto...', icon: Icons.search),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Proveedores registrados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Text('${lista.length}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: lista.isEmpty
                        ? const Center(child: Text('No hay proveedores con ese criterio.', style: TextStyle(color: AppTheme.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: lista.length,
                            itemBuilder: (context, i) => Aparicion(indice: i, child: _buildTarjeta(lista[i])),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTarjeta(Proveedor p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFFF1F2F4), shape: BoxShape.circle),
            child: const Icon(Icons.storefront_outlined, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  p.contacto.isEmpty ? 'Sin contacto registrado' : p.contacto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    Text('${p.id} • Entrega en ${p.tiempoEntregaDias} ${p.tiempoEntregaDias == 1 ? 'día' : 'días'}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                    if (p.precioPromedio != null)
                      Text('Precio prom. \$ ${p.precioPromedio!.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          if (Sesion.editaCompras) ...[
            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), tooltip: 'Editar', onPressed: () => _abrirFormulario(p)),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
              tooltip: 'Eliminar',
              onPressed: () => _eliminar(p),
            ),
          ],
        ],
      ),
    );
  }
}

class _FormularioProveedor extends StatefulWidget {
  final Proveedor? proveedor;

  const _FormularioProveedor({this.proveedor});

  @override
  State<_FormularioProveedor> createState() => _FormularioProveedorState();
}

class _FormularioProveedorState extends State<_FormularioProveedor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _contacto;
  late final TextEditingController _direccion;
  late final TextEditingController _dias;
  late final TextEditingController _precio;
  String? _error;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedor;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _contacto = TextEditingController(text: p?.contacto ?? '');
    _direccion = TextEditingController(text: p?.direccion ?? '');
    _dias = TextEditingController(text: (p?.tiempoEntregaDias ?? 3).toString());
    _precio = TextEditingController(text: p?.precioPromedio?.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _nombre.dispose();
    _contacto.dispose();
    _direccion.dispose();
    _dias.dispose();
    _precio.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final error = await ProveedoresStore.instancia.guardar(
      existente: widget.proveedor,
      nombre: _nombre.text.trim(),
      contacto: _contacto.text.trim(),
      direccion: _direccion.text.trim(),
      tiempoEntregaDias: int.parse(_dias.text),
      precioPromedio: double.tryParse(_precio.text.trim()),
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(widget.proveedor == null ? 'Proveedor registrado.' : 'Proveedor actualizado.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.proveedor == null ? 'Nuevo proveedor' : 'Editar proveedor',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Nombre del proveedor *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nombre,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                decoration: AppTheme.inputDecoration('Ej. Refacciones Diésel del Norte', icon: Icons.storefront_outlined),
              ),
              const SizedBox(height: 14),
              const Text('Contacto', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contacto,
                decoration: AppTheme.inputDecoration('Teléfono o correo', icon: Icons.phone_outlined),
              ),
              const SizedBox(height: 14),
              const Text('Dirección (aparece en la orden de compra)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _direccion,
                maxLines: 2,
                decoration: AppTheme.inputDecoration('Calle, número, colonia, ciudad, CP', icon: Icons.place_outlined),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Días de entrega *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _dias,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                          validator: (v) => int.tryParse(v ?? '') == null ? 'Requerido' : null,
                          decoration: AppTheme.inputDecoration('3', icon: Icons.local_shipping_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Precio promedio', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _precio,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                          decoration: AppTheme.inputDecoration('Opcional', icon: Icons.attach_money),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    widget.proveedor == null ? 'Guardar proveedor' : 'Guardar cambios',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
