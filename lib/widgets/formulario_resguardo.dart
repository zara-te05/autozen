import 'package:flutter/material.dart';
import '../models/resguardo.dart';
import '../services/almacen_store.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import 'firma_pad.dart';

/// Registrar la entrega de placas (u otras piezas) de un camión al almacén.
Future<void> mostrarFormularioResguardo(BuildContext context) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => const _FormularioResguardo(),
    );

class _FormularioResguardo extends StatefulWidget {
  const _FormularioResguardo();

  @override
  State<_FormularioResguardo> createState() => _FormularioResguardoState();
}

class _FormularioResguardoState extends State<_FormularioResguardo> {
  final _formKey = GlobalKey<FormState>();
  final _firma = GlobalKey<FirmaPadState>();
  final TextEditingController _numero = TextEditingController();
  final TextEditingController _objetos = TextEditingController(text: 'Placas');
  final TextEditingController _operador = TextEditingController();
  String _empresa = '';
  String _tipo = '';
  DateTime _fecha = DateTime.now();
  bool _guardando = false;

  @override
  void dispose() {
    _numero.dispose();
    _objetos.dispose();
    _operador.dispose();
    super.dispose();
  }

  void _agregarObjeto(String o) {
    final actual = _objetos.text.trim();
    if (actual.toLowerCase().contains(o.toLowerCase())) return;
    _objetos.text = actual.isEmpty ? o : '$actual, $o';
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    if (_firma.currentState?.vacia ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falta la firma del operador.'), backgroundColor: AppTheme.danger));
      return;
    }
    setState(() => _guardando = true);
    final firma = await _firma.currentState!.exportar();
    final error = await AlmacenStore.instancia.registrarResguardo(
      empresa: _empresa,
      tipoUnidad: _tipo,
      numeroUnidad: _numero.text,
      objetos: _objetos.text,
      fechaIngreso: _fecha,
      operador: _operador.text,
      firma: firma,
    );
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.danger));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Entrega registrada en almacén.'), backgroundColor: AppTheme.success));
  }

  Widget _autocompletar({
    required String etiqueta,
    required String hint,
    required List<String> opciones,
    required ValueChanged<String> onChanged,
    bool requerido = false,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (valor) {
        final q = valor.text.toLowerCase();
        return opciones.where((o) => o.toLowerCase().contains(q));
      },
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, foco, alEnviar) => TextFormField(
        controller: controller,
        focusNode: foco,
        onChanged: onChanged,
        textCapitalization: TextCapitalization.words,
        validator: requerido ? (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null : null,
        decoration: AppTheme.inputDecoration(hint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previos = AlmacenStore.instancia.resguardos;
    final empresas = {for (final r in previos) r.empresa}.where((e) => e.isNotEmpty).toList()..sort();
    final tipos = {...tiposUnidadSugeridos, for (final r in previos) r.tipoUnidad}.where((t) => t.isNotEmpty).toList();

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
                  const Expanded(child: Text('Entrega de placas a almacén', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              _etiqueta('Empresa *'),
              _autocompletar(etiqueta: 'Empresa', hint: 'Ej. TGL', opciones: empresas, onChanged: (v) => _empresa = v, requerido: true),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta('Tipo de unidad'),
                        _autocompletar(etiqueta: 'Tipo', hint: 'Ej. Tanque', opciones: tipos, onChanged: (v) => _tipo = v),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta('No. de unidad'),
                        TextFormField(controller: _numero, decoration: AppTheme.inputDecoration('Ej. 184 (vacío = S/N)')),
                      ],
                    ),
                  ),
                ],
              ),
              _etiqueta('¿Qué se entrega? *'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final o in objetosSugeridos)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      label: Text(o, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade50,
                      side: const BorderSide(color: AppTheme.border),
                      onPressed: () => _agregarObjeto(o),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _objetos,
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica qué se entrega' : null,
                decoration: AppTheme.inputDecoration('Placas, válvula de descarga...'),
              ),
              _etiqueta('Fecha de ingreso a almacén'),
              InkWell(
                onTap: () async {
                  final f = await showDatePicker(context: context, initialDate: _fecha, firstDate: DateTime(2025), lastDate: DateTime.now());
                  if (f != null) setState(() => _fecha = f);
                },
                borderRadius: BorderRadius.circular(14),
                child: InputDecorator(
                  decoration: AppTheme.inputDecoration('', icon: Icons.calendar_today),
                  child: Text(formatearFecha(_fecha)),
                ),
              ),
              _etiqueta('Operador que entrega *'),
              TextFormField(
                controller: _operador,
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica el nombre del operador' : null,
                decoration: AppTheme.inputDecoration('Nombre del operador', icon: Icons.person_outline),
              ),
              _etiqueta('Firma del operador *'),
              FirmaPad(key: _firma),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: const Icon(Icons.inventory_outlined, color: Colors.white),
                  label: const Text('Registrar entrega', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
