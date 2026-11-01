import 'package:flutter/material.dart';
import '../models/catalogos.dart';
import '../services/catalogos_store.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/safe_number_picker.dart';
import '../widgets/menu_lateral.dart';

const Map<String, IconData> iconosDepartamento = {
  'business': Icons.business_outlined,
  'build': Icons.build_outlined,
  'shopping': Icons.shopping_bag_outlined,
  'inventory': Icons.inventory_2_outlined,
  'fact_check': Icons.fact_check_outlined,
  'engineering': Icons.engineering_outlined,
};

class DepartamentosScreen extends StatefulWidget {
  const DepartamentosScreen({super.key});

  @override
  State<DepartamentosScreen> createState() => _DepartamentosScreenState();
}

class _DepartamentosScreenState extends State<DepartamentosScreen> {
  final CatalogosStore _store = CatalogosStore.instancia;

  Future<void> _abrirFormulario([Departamento? depto]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => _FormularioDepartamento(departamento: depto),
      );

  Future<void> _eliminar(Departamento depto) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar departamento',
      message: '¿Eliminar el área "${depto.nombre}"?',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      icon: Icons.domain_disabled_rounded,
    );
    if (!confirmar) return;
    final error = await _store.eliminarDepartamento(depto);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Departamento "${depto.nombre}" eliminado.'), backgroundColor: error == null ? AppTheme.success : AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const MenuLateral(seccion: Seccion.departamentos),
      appBar: AppBar(title: const Text('Gestión de Departamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_business_outlined, color: Colors.white),
        label: const Text('Nuevo departamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ContenidoResponsivo(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) {
            final lista = _store.departamentos;
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Áreas operativas del taller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      Text('${lista.length} activas', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: lista.isEmpty
                        ? const Center(child: Text('No hay departamentos registrados.', style: TextStyle(color: AppTheme.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 96),
                            itemCount: lista.length,
                            itemBuilder: (context, i) => _buildTarjeta(lista[i]),
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

  Widget _buildTarjeta(Departamento d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(color: Color(0xFFF1F2F4), shape: BoxShape.circle),
            child: Icon(iconosDepartamento[d.icono] ?? Icons.business_outlined, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('Encargado: ${d.encargado.isEmpty ? 'Sin asignar' : d.encargado}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Text('${d.personal}', style: const TextStyle(color: AppTheme.info, fontWeight: FontWeight.bold, fontSize: 15)),
                const Text('Personal', style: TextStyle(color: AppTheme.info, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), tooltip: 'Editar', onPressed: () => _abrirFormulario(d)),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
            tooltip: 'Eliminar área',
            onPressed: () => _eliminar(d),
          ),
        ],
      ),
    );
  }
}

class _FormularioDepartamento extends StatefulWidget {
  final Departamento? departamento;

  const _FormularioDepartamento({this.departamento});

  @override
  State<_FormularioDepartamento> createState() => _FormularioDepartamentoState();
}

class _FormularioDepartamentoState extends State<_FormularioDepartamento> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre = TextEditingController(text: widget.departamento?.nombre ?? '');
  late final TextEditingController _encargado = TextEditingController(text: widget.departamento?.encargado ?? '');
  late String _icono = widget.departamento?.icono ?? 'business';
  late int _personal = widget.departamento?.personal ?? 0;
  bool _guardando = false;

  @override
  void dispose() {
    _nombre.dispose();
    _encargado.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final error = await CatalogosStore.instancia.guardarDepartamento(
      Departamento(id: widget.departamento?.id ?? 0, nombre: _nombre.text.trim(), encargado: _encargado.text.trim(), icono: _icono, personal: _personal),
      existente: widget.departamento,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.danger));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Departamento guardado.'), backgroundColor: AppTheme.success));
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
                    child: Text(widget.departamento == null ? 'Nuevo departamento' : 'Editar departamento',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Nombre del área *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nombre,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del área' : null,
                decoration: AppTheme.inputDecoration('Ej. Diagnóstico electrónico'),
              ),
              const SizedBox(height: 14),
              const Text('Encargado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(controller: _encargado, decoration: AppTheme.inputDecoration('Nombre del encargado', icon: Icons.person_outline)),
              const SizedBox(height: 14),
              const Text('Ícono', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in iconosDepartamento.entries)
                    InkWell(
                      onTap: () => setState(() => _icono = e.key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _icono == e.key ? AppTheme.primary : AppTheme.inputFill,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _icono == e.key ? AppTheme.primary : AppTheme.border),
                        ),
                        child: Icon(e.value, color: _icono == e.key ? Colors.white : AppTheme.textPrimary, size: 22),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SafeNumberPicker(
                label: 'Personal asignado',
                value: _personal,
                min: 0,
                max: 200,
                unit: 'personas',
                onChanged: (n) => setState(() => _personal = n),
              ),
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
                  child: const Text('Guardar departamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
