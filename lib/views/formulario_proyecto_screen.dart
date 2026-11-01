import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/proyecto_taller.dart';
import '../services/proyectos_store.dart';
import '../utils/app_theme.dart';
import '../utils/formateadores.dart';
import '../utils/formato_fecha.dart';
import '../widgets/contenido_responsivo.dart';

/// Crear o editar un proyecto: datos del camión y etapas configurables.
class FormularioProyectoScreen extends StatefulWidget {
  final TipoProyecto tipo;

  /// Si se pasa, el formulario edita este proyecto; si no, crea uno nuevo.
  final ProyectoTaller? proyecto;

  const FormularioProyectoScreen({super.key, required this.tipo, this.proyecto});

  @override
  State<FormularioProyectoScreen> createState() => _FormularioProyectoScreenState();
}

class _EtapaEditable {
  final Key key = UniqueKey();
  final TextEditingController nombre;
  final TextEditingController dias;

  _EtapaEditable(String nombreInicial, int diasIniciales)
      : nombre = TextEditingController(text: nombreInicial),
        dias = TextEditingController(text: diasIniciales.toString());

  void dispose() {
    nombre.dispose();
    dias.dispose();
  }
}

class _FormularioProyectoScreenState extends State<FormularioProyectoScreen> {
  static const int _maxEtapas = 15;
  static const int _maxDiasPorEtapa = 365;

  final _formKey = GlobalKey<FormState>();
  final ProyectosStore _store = ProyectosStore.instancia;

  late final TextEditingController _camionCtrl;
  late final TextEditingController _clienteCtrl;
  late final TextEditingController _placaCtrl;
  late final TextEditingController _responsableCtrl;
  late final TextEditingController _aseguradoraCtrl;
  late final TextEditingController _siniestroCtrl;
  late List<_EtapaEditable> _etapas;
  late int _etapaActual;

  /// Solo aseguradora: fecha prometida de entrega.
  DateTime? _fechaEntrega;
  bool _guardando = false;

  bool get _editando => widget.proyecto != null;
  TipoProyecto get _tipo => widget.proyecto?.tipo ?? widget.tipo;

  @override
  void initState() {
    super.initState();
    final p = widget.proyecto;
    _camionCtrl = TextEditingController(text: p?.nombreCamion ?? '');
    _clienteCtrl = TextEditingController(text: p?.cliente ?? '');
    _placaCtrl = TextEditingController(text: p?.placa ?? '');
    _responsableCtrl = TextEditingController(text: p?.responsable ?? '');
    _aseguradoraCtrl = TextEditingController(text: p?.aseguradora ?? '');
    _siniestroCtrl = TextEditingController(text: p?.numeroSiniestro ?? '');
    final etapasIniciales = p?.etapas ?? ProyectoTaller.etapasPorDefecto(_tipo);
    _etapas = etapasIniciales.map((e) => _EtapaEditable(e.nombre, e.diasEstimados)).toList();
    _etapaActual = p?.etapaActual ?? 0;
    _fechaEntrega = p?.fechaEntregaComprometida;
  }

  DateTime get _fechaIngreso => widget.proyecto?.fechaIngreso ?? DateTime.now();

  Future<void> _seleccionarFechaEntrega(FormFieldState<DateTime> campo) async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? _fechaIngreso.add(Duration(days: _diasTotales)),
      firstDate: _fechaIngreso,
      lastDate: DateTime(DateTime.now().year + 2),
      helpText: 'Fecha de entrega a la aseguradora',
    );
    if (seleccion == null) return;
    setState(() => _fechaEntrega = seleccion);
    campo.didChange(seleccion);
  }

  @override
  void dispose() {
    for (final c in [_camionCtrl, _clienteCtrl, _placaCtrl, _responsableCtrl, _aseguradoraCtrl, _siniestroCtrl]) {
      c.dispose();
    }
    for (final e in _etapas) {
      e.dispose();
    }
    super.dispose();
  }

  int get _diasTotales => _etapas.fold(0, (suma, e) => suma + (int.tryParse(e.dias.text) ?? 0));

  void _agregarEtapa() {
    if (_etapas.length >= _maxEtapas) return;
    setState(() => _etapas.add(_EtapaEditable('', 1)));
  }

  void _quitarEtapa(int index) {
    if (_etapas.length <= 1) return;
    final quitada = _etapas[index];
    WidgetsBinding.instance.addPostFrameCallback((_) => quitada.dispose());
    setState(() {
      _etapas.removeAt(index);
      // Mantener la etapa en curso apuntando a la misma etapa o a la anterior válida
      if (index < _etapaActual) _etapaActual--;
      if (_etapaActual > _etapas.length) _etapaActual = _etapas.length;
    });
  }

  void _moverEtapa(int index, int direccion) {
    final destino = index + direccion;
    if (destino < 0 || destino >= _etapas.length) return;
    setState(() {
      final etapa = _etapas.removeAt(index);
      _etapas.insert(destino, etapa);
      if (_etapaActual == index) {
        _etapaActual = destino;
      } else if (_etapaActual == destino) {
        _etapaActual = index;
      }
    });
  }

  Future<void> _guardar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;

    final etapas = _etapas
        .map((e) => EtapaProyecto(nombre: e.nombre.text.trim(), diasEstimados: int.parse(e.dias.text)))
        .toList();
    final bool esAseguradora = _tipo == TipoProyecto.aseguradora;
    final original = widget.proyecto;
    final datos = ProyectoTaller(
      id: original?.id ?? _store.siguienteId(_tipo),
      tipo: _tipo,
      nombreCamion: _camionCtrl.text.trim(),
      cliente: esAseguradora ? '' : _clienteCtrl.text.trim(),
      placa: _placaCtrl.text.trim(),
      responsable: _responsableCtrl.text.trim(),
      aseguradora: esAseguradora ? _aseguradoraCtrl.text.trim() : null,
      numeroSiniestro: esAseguradora && _siniestroCtrl.text.trim().isNotEmpty ? _siniestroCtrl.text.trim() : null,
      fechaEntregaComprometida: esAseguradora ? _fechaEntrega : null,
      fechaIngreso: original?.fechaIngreso ?? DateTime.now(),
      etapas: etapas,
      etapaActual: _etapaActual.clamp(0, etapas.length),
      archivado: original?.archivado ?? false,
      // La evaluación y las fotos no se editan aquí: se conservan
      fechaEvaluacion: original?.fechaEvaluacion,
      descripcionDanos: original?.descripcionDanos ?? '',
      refaccionesCotizadas: original?.refaccionesCotizadas,
      fotos: original?.fotos,
    );

    setState(() => _guardando = true);
    final String? error = original != null
        ? await _store.actualizarProyecto(original, datos)
        : (await _store.crear(datos)).error;
    if (!mounted) return;
    setState(() => _guardando = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.danger));
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context, true);
    messenger.showSnackBar(
      SnackBar(
        content: Text(_editando ? 'Cambios guardados.' : 'Proyecto "${datos.nombreCamion}" creado.'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_editando ? 'Editar proyecto' : 'Nuevo ${_tipo.singular}'),
      ),
      body: ContenidoResponsivo(
        anchoMaximo: 760,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _buildSeccion(
                titulo: 'Datos de la unidad',
                children: [
                  _buildCampo(
                    etiqueta: 'Nombre del camión *',
                    controller: _camionCtrl,
                    hint: 'Ej. Kenworth T680 2021',
                    icono: Icons.local_shipping_outlined,
                    validator: _requerido('Ingresa el nombre del camión'),
                  ),
                  _buildCampo(
                    etiqueta: 'Placa *',
                    controller: _placaCtrl,
                    hint: 'Ej. DUR-4821',
                    icono: Icons.pin_outlined,
                    formatters: formateadoresPlaca,
                    validator: _requerido('Ingresa la placa'),
                  ),
                  if (_tipo == TipoProyecto.cliente)
                    _buildCampo(
                      etiqueta: 'Cliente *',
                      controller: _clienteCtrl,
                      hint: 'Nombre o empresa del cliente',
                      icono: Icons.person_outline,
                      validator: _requerido('Ingresa el cliente'),
                    )
                  else ...[
                    _buildCampo(
                      etiqueta: 'Aseguradora *',
                      controller: _aseguradoraCtrl,
                      hint: 'Ej. Seguros Atlas',
                      icono: Icons.verified_user_outlined,
                      validator: _requerido('Ingresa la aseguradora'),
                    ),
                    _buildCampo(
                      etiqueta: 'Número de siniestro',
                      controller: _siniestroCtrl,
                      hint: 'Opcional',
                      icono: Icons.confirmation_number_outlined,
                    ),
                    _buildCampoFechaEntrega(),
                  ],
                  _buildCampo(
                    etiqueta: 'Responsable',
                    controller: _responsableCtrl,
                    hint: 'Opcional',
                    icono: Icons.engineering_outlined,
                    ultimo: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSeccionEtapas(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: Text(
                    _editando ? 'Guardar cambios' : 'Crear proyecto',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _requerido(String mensaje) {
    return (v) => (v == null || v.trim().isEmpty) ? mensaje : null;
  }

  Widget _buildSeccion({required String titulo, Widget? accion, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ?accion,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCampo({
    required String etiqueta,
    required TextEditingController controller,
    required String hint,
    required IconData icono,
    FormFieldValidator<String>? validator,
    List<TextInputFormatter>? formatters,
    bool ultimo = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            inputFormatters: formatters,
            textInputAction: TextInputAction.next,
            decoration: AppTheme.inputDecoration(hint, icon: icono),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionEtapas() {
    final int dias = _diasTotales;

    return _buildSeccion(
      titulo: 'Etapas del proyecto',
      accion: Text(
        '${_etapas.length} etapas • $dias días',
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      children: [
        const Text(
          'Define cuántas etapas tiene la reparación, cómo se llaman y cuántos días se estima cada una.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        if (_tipo == TipoProyecto.aseguradora && _fechaEntrega != null) ...[
          const SizedBox(height: 10),
          _buildAvisoPlan(dias),
        ],
        const SizedBox(height: 14),
        for (int i = 0; i < _etapas.length; i++) _buildEtapa(i),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _etapas.length < _maxEtapas ? _agregarEtapa : null,
            icon: const Icon(Icons.add, size: 18, color: AppTheme.primary),
            label: Text(
              _etapas.length < _maxEtapas ? 'Agregar etapa' : 'Máximo $_maxEtapas etapas',
              style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text('Etapa en curso', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          // La clave cambia con la lista para que el selector nunca apunte a una etapa borrada
          key: ValueKey('etapa-actual-${_etapas.length}-$_etapaActual'),
          initialValue: _etapaActual.clamp(0, _etapas.length),
          isExpanded: true,
          decoration: AppTheme.inputDecoration('Selecciona la etapa', icon: Icons.flag_outlined),
          items: [
            for (int i = 0; i < _etapas.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  'Etapa ${i + 1}: ${_etapas[i].nombre.text.trim().isEmpty ? 'Sin nombre' : _etapas[i].nombre.text.trim()}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            DropdownMenuItem(value: _etapas.length, child: const Text('Terminado (todas las etapas completas)')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _etapaActual = val);
          },
        ),
      ],
    );
  }

  Widget _buildCampoFechaEntrega() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fecha de entrega *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
          const SizedBox(height: 6),
          FormField<DateTime>(
            initialValue: _fechaEntrega,
            validator: (v) => v == null ? 'Elige la fecha de entrega comprometida' : null,
            builder: (campo) => InkWell(
              onTap: () => _seleccionarFechaEntrega(campo),
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: AppTheme.inputDecoration('Fecha', icon: Icons.event_busy_outlined).copyWith(errorText: campo.errorText),
                child: Text(
                  _fechaEntrega == null ? 'Selecciona la fecha prometida' : formatearFecha(_fechaEntrega!),
                  style: TextStyle(color: _fechaEntrega == null ? AppTheme.textMuted : AppTheme.textPrimary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Fecha comprometida con la aseguradora: si no se entrega ese día, hay multa.',
            style: TextStyle(color: AppTheme.warning, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Compara el plan de etapas contra la fecha prometida a la aseguradora.
  Widget _buildAvisoPlan(int diasPlan) {
    final int diasDisponibles = ProyectoTaller.diasEntre(_fechaIngreso, _fechaEntrega!);
    final bool excede = diasPlan > diasDisponibles;
    final Color color = excede ? AppTheme.danger : AppTheme.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        excede
            ? 'El plan suma $diasPlan días, pero solo hay $diasDisponibles hasta la entrega (${formatearFecha(_fechaEntrega!)}). '
                'Reduce días o la aseguradora multará.'
            : 'El plan ($diasPlan días) cabe antes de la entrega del ${formatearFecha(_fechaEntrega!)} ($diasDisponibles días disponibles).',
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildEtapa(int index) {
    final etapa = _etapas[index];
    final bool esActual = index == _etapaActual;

    return Container(
      key: etapa.key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: esActual ? const Color(0xFFF4F4F5) : AppTheme.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: esActual ? AppTheme.primary : AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: index < _etapaActual || esActual ? AppTheme.primary : AppTheme.border,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: index < _etapaActual || esActual ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  esActual ? 'Etapa ${index + 1} • en curso' : 'Etapa ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_upward, size: 18),
                tooltip: 'Subir',
                onPressed: index > 0 ? () => _moverEtapa(index, -1) : null,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_downward, size: 18),
                tooltip: 'Bajar',
                onPressed: index < _etapas.length - 1 ? () => _moverEtapa(index, 1) : null,
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                tooltip: 'Quitar etapa',
                onPressed: _etapas.length > 1 ? () => _quitarEtapa(index) : null,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: etapa.nombre,
                  onChanged: (_) => setState(() {}),
                  inputFormatters: [LengthLimitingTextInputFormatter(40)],
                  validator: _requerido('Nombre de la etapa'),
                  decoration: AppTheme.inputDecoration('Nombre de la etapa'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 112,
                child: TextFormField(
                  controller: etapa.dias,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  // Solo dígitos: no se pueden escribir negativos ni decimales
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1) return 'Mín. 1';
                    if (n > _maxDiasPorEtapa) return 'Máx. $_maxDiasPorEtapa';
                    return null;
                  },
                  decoration: AppTheme.inputDecoration('Días').copyWith(suffixText: 'días'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
