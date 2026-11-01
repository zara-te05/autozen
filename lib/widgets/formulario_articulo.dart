import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/almacen_inventario.dart';
import '../services/almacen_store.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import 'dialogo_categorias.dart';

/// Formateador de cantidades según la unidad: enteros para piezas, hasta 3 decimales para kg/L/m.
List<TextInputFormatter> formateadoresCantidad(UnidadMedida unidad) => unidad.permiteDecimales
    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')), LengthLimitingTextInputFormatter(10)]
    : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)];

/// Alta o edición de un artículo del almacén (material o herramienta).
class FormularioArticulo extends StatefulWidget {
  final Articulo? articulo;
  final VoidCallback? onGuardado;

  const FormularioArticulo({super.key, this.articulo, this.onGuardado});

  @override
  State<FormularioArticulo> createState() => _FormularioArticuloState();
}

class _FormularioArticuloState extends State<FormularioArticulo> {
  final AlmacenStore _store = AlmacenStore.instancia;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombre;
  late final TextEditingController _existencia;
  late final TextEditingController _costo;
  late TipoArticulo _tipo;
  late UnidadMedida _unidad;
  String? _categoria;
  bool _guardando = false;

  bool get _editando => widget.articulo != null;

  @override
  void initState() {
    super.initState();
    final a = widget.articulo;
    _nombre = TextEditingController(text: a?.nombre ?? '');
    _existencia = TextEditingController(text: a == null ? '' : _texto(a.existencia));
    _costo = TextEditingController(text: a == null ? '' : a.costoUnitario.toStringAsFixed(2));
    _tipo = a?.tipo ?? TipoArticulo.material;
    _unidad = a?.unidad ?? UnidadMedida.pieza;
    _categoria = a?.categoria;
  }

  static String _texto(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _nombre.dispose();
    _existencia.dispose();
    _costo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);
    final error = await _store.guardarArticulo(
      existente: widget.articulo,
      nombre: _nombre.text,
      categoria: _categoria!,
      tipo: _tipo,
      unidad: _unidad,
      existencia: double.parse(_existencia.text),
      costoUnitario: double.tryParse(_costo.text) ?? 0,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.danger));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editando ? 'Artículo actualizado.' : '"${_nombre.text.trim()}" dado de alta en almacén.'),
        backgroundColor: AppTheme.success,
      ),
    );
    if (!_editando) {
      _formKey.currentState!.reset();
      _nombre.clear();
      _existencia.clear();
      _costo.clear();
      setState(() {});
    }
    widget.onGuardado?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final categorias = _store.categorias;
        if (_categoria != null && !categorias.contains(_categoria)) _categoria = null;
        final double existencia = double.tryParse(_existencia.text) ?? 0;
        final double costo = double.tryParse(_costo.text) ?? 0;

        return Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _editando ? 'Editar artículo' : 'Alta de artículo',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF1F2F4), borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            widget.articulo?.id ?? _store.siguienteIdArticulo(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _etiqueta('¿Qué es?'),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<TipoArticulo>(
                        segments: const [
                          ButtonSegment(value: TipoArticulo.material, icon: Icon(Icons.inventory_2_outlined), label: Text('Material')),
                          ButtonSegment(value: TipoArticulo.herramienta, icon: Icon(Icons.handyman_outlined), label: Text('Herramienta')),
                        ],
                        selected: {_tipo},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => setState(() => _tipo = s.first),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tipo == TipoArticulo.material
                          ? 'Se consume en el proyecto y su costo se suma a lo invertido.'
                          : 'Se presta a un proyecto y debe regresar al almacén.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    const SizedBox(height: 16),
                    _etiqueta('Nombre *'),
                    TextFormField(
                      controller: _nombre,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del artículo' : null,
                      decoration: AppTheme.inputDecoration(
                        _tipo == TipoArticulo.material ? 'Ej. Aceite 15W40' : 'Ej. Martillo de bola 32 oz',
                        icon: _tipo == TipoArticulo.material ? Icons.inventory_2_outlined : Icons.handyman_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _etiqueta('Categoría *'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('categoria-$_categoria-${categorias.length}'),
                            initialValue: _categoria,
                            isExpanded: true,
                            decoration: AppTheme.inputDecoration('Selecciona', icon: Icons.category_outlined),
                            items: [for (final c in categorias) DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))],
                            validator: (v) => v == null ? 'Elige una categoría' : null,
                            onChanged: (v) => setState(() => _categoria = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: IconButton.outlined(
                            icon: const Icon(Icons.edit_note),
                            tooltip: 'Crear, editar o eliminar categorías',
                            onPressed: () => mostrarDialogoCategorias(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _etiqueta('Unidad de medida *'),
                    DropdownButtonFormField<UnidadMedida>(
                      initialValue: _unidad,
                      isExpanded: true,
                      decoration: AppTheme.inputDecoration('Unidad', icon: Icons.straighten),
                      items: [
                        for (final u in UnidadMedida.values)
                          DropdownMenuItem(value: u, child: Text('${u.nombre} (${u.abreviatura})')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _unidad = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _etiqueta(_editando ? 'Existencia *' : 'Cantidad inicial *'),
                              TextFormField(
                                key: ValueKey('existencia-${_unidad.name}'),
                                controller: _existencia,
                                keyboardType: TextInputType.numberWithOptions(decimal: _unidad.permiteDecimales),
                                inputFormatters: formateadoresCantidad(_unidad),
                                onChanged: (_) => setState(() {}),
                                validator: (v) {
                                  final n = double.tryParse(v ?? '');
                                  if (n == null) return 'Requerido';
                                  if (!_unidad.permiteDecimales && n != n.roundToDouble()) return 'Sin decimales';
                                  return null;
                                },
                                decoration: AppTheme.inputDecoration('0').copyWith(suffixText: _unidad.abreviatura),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _etiqueta('Costo por ${_unidad.abreviatura} *'),
                              TextFormField(
                                controller: _costo,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                                onChanged: (_) => setState(() {}),
                                validator: (v) => double.tryParse(v ?? '') == null ? 'Requerido' : null,
                                decoration: AppTheme.inputDecoration('0.00', icon: Icons.attach_money),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Valor en almacén: ${formatearDinero(existencia * costo)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: categorias.isEmpty || _guardando ? null : _guardar,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    categorias.isEmpty
                        ? 'Crea una categoría primero'
                        : (_editando ? 'Guardar cambios' : 'Dar de alta en almacén'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _etiqueta(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
      );
}
