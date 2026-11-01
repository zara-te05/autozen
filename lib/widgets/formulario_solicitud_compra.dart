import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/compras.dart';
import '../models/proyecto_taller.dart';
import '../services/compras_store.dart';
import '../services/proyectos_store.dart';
import '../utils/app_theme.dart';

/// Abre el formulario para pedir a Compras lo que necesita un proyecto.
Future<void> mostrarSolicitudCompra(BuildContext context, {ProyectoTaller? proyecto}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => _FormularioSolicitud(proyecto: proyecto),
  );
}

class _FormularioSolicitud extends StatefulWidget {
  final ProyectoTaller? proyecto;

  const _FormularioSolicitud({this.proyecto});

  @override
  State<_FormularioSolicitud> createState() => _FormularioSolicitudState();
}

class _FormularioSolicitudState extends State<_FormularioSolicitud> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcion = TextEditingController();
  final TextEditingController _cantidad = TextEditingController(text: '1');
  final TextEditingController _notas = TextEditingController();
  late String? _proyectoId = widget.proyecto?.id;
  String _unidad = unidadesOrden.first;
  bool _guardando = false;

  @override
  void dispose() {
    _descripcion.dispose();
    _cantidad.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    final proyecto = widget.proyecto ?? ProyectosStore.instancia.activos.firstWhere((p) => p.id == _proyectoId);
    setState(() => _guardando = true);
    final error = await ComprasStore.instancia.solicitar(
      proyecto: proyecto,
      descripcion: _descripcion.text,
      cantidad: double.parse(_cantidad.text),
      unidad: _unidad,
      notas: _notas.text,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.danger));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Solicitud enviada a Compras.'), backgroundColor: AppTheme.success));
  }

  @override
  Widget build(BuildContext context) {
    final proyectos = ProyectosStore.instancia.activos;
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
                  const Expanded(child: Text('Solicitar compra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Text('Compras recibirá la solicitud y generará la orden.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              _etiqueta('Proyecto *'),
              if (widget.proyecto != null)
                InputDecorator(
                  decoration: AppTheme.inputDecoration('', icon: Icons.local_shipping_outlined, readOnly: true),
                  child: Text('${widget.proyecto!.id} • ${widget.proyecto!.nombreCamion} (${widget.proyecto!.placa})', overflow: TextOverflow.ellipsis),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _proyectoId,
                  isExpanded: true,
                  decoration: AppTheme.inputDecoration('Selecciona el proyecto', icon: Icons.local_shipping_outlined),
                  items: [
                    for (final p in proyectos)
                      DropdownMenuItem(value: p.id, child: Text('${p.id} • ${p.nombreCamion} (${p.placa})', overflow: TextOverflow.ellipsis)),
                  ],
                  validator: (v) => v == null ? 'Elige el proyecto' : null,
                  onChanged: (v) => setState(() => _proyectoId = v),
                ),
              _etiqueta('¿Qué se necesita? *'),
              TextFormField(
                controller: _descripcion,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe el nombre de lo que se necesita' : null,
                decoration: AppTheme.inputDecoration('Ej. Electrodo 6010 de 1/8"', icon: Icons.shopping_cart_outlined),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta('Cantidad *'),
                        TextFormField(
                          controller: _cantidad,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}'))],
                          validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Mayor a 0' : null,
                          decoration: AppTheme.inputDecoration('1'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta('Unidad'),
                        DropdownButtonFormField<String>(
                          initialValue: _unidad,
                          isExpanded: true,
                          decoration: AppTheme.inputDecoration('Unidad'),
                          items: [for (final u in unidadesOrden) DropdownMenuItem(value: u, child: Text(u))],
                          onChanged: (v) => setState(() => _unidad = v ?? _unidad),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _etiqueta('Notas para Compras'),
              TextFormField(
                controller: _notas,
                maxLines: 2,
                decoration: AppTheme.inputDecoration('Opcional: marca, medida, urgencia...'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _enviar,
                  icon: const Icon(Icons.send_outlined, color: Colors.white),
                  label: const Text('Enviar solicitud', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiqueta(String texto) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
