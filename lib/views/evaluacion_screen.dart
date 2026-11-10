import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/proyecto_taller.dart';
import '../services/fotos_service.dart';
import '../services/proyectos_store.dart';
import '../services/sesion.dart';
import '../utils/app_theme.dart';
import '../utils/formateadores.dart';
import '../utils/formato_fecha.dart';
import '../widgets/aviso_solo_lectura.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/galeria_fotos.dart';
import '../widgets/safe_number_picker.dart';
import 'detalle_proyecto_screen.dart';
import '../widgets/menu_lateral.dart';

/// Evaluación de Daños: el primer paso de todo proyecto. Al guardarla se crea el proyecto
/// con los datos de la unidad, el diagnóstico, la cotización y las fotos.
class EvaluacionScreen extends StatefulWidget {
  /// Si viene de un apartado de proyectos, el tipo ya está decidido.
  final TipoProyecto? tipo;

  const EvaluacionScreen({super.key, this.tipo});

  @override
  State<EvaluacionScreen> createState() => _EvaluacionScreenState();
}

class _RefaccionEditable {
  final TextEditingController nombre = TextEditingController();
  int cantidad = 1;
}

class _EvaluacionScreenState extends State<EvaluacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProyectosStore _store = ProyectosStore.instancia;

  final TextEditingController _camionCtrl = TextEditingController();
  final TextEditingController _placaCtrl = TextEditingController();
  final TextEditingController _clienteCtrl = TextEditingController();
  final TextEditingController _aseguradoraCtrl = TextEditingController();
  final TextEditingController _siniestroCtrl = TextEditingController();
  final TextEditingController _responsableCtrl = TextEditingController();
  final TextEditingController _diasCtrl = TextEditingController();
  final TextEditingController _descripcionCtrl = TextEditingController();

  late TipoProyecto _tipo;
  DateTime _fechaInspeccion = DateTime.now();

  /// Solo aseguradora: fecha prometida de entrega.
  DateTime? _fechaEntrega;
  final List<String> _fotos = [];
  final List<_RefaccionEditable> _refacciones = [_RefaccionEditable()];
  bool _guardado = false;
  bool _guardando = false;

  static const List<String> _danosComunes = [
    'Falla en embrague',
    'Fuga de fluido de frenos',
    'Desalineación de chasis',
    'Filtro obstruido',
    'Amortiguador reventado',
    'Golpe en cabina / pintura',
  ];

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipo ?? TipoProyecto.cliente;
  }

  @override
  void dispose() {
    for (final c in [_camionCtrl, _placaCtrl, _clienteCtrl, _aseguradoraCtrl, _siniestroCtrl, _responsableCtrl, _diasCtrl, _descripcionCtrl]) {
      c.dispose();
    }
    for (final r in _refacciones) {
      r.nombre.dispose();
    }
    // Si se salió sin guardar, las fotos tomadas no pertenecen a ningún proyecto
    if (!_guardado) {
      for (final ruta in _fotos) {
        FotosService.borrar(ruta);
      }
    }
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaInspeccion,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (seleccion != null) setState(() => _fechaInspeccion = seleccion);
  }

  /// Etapas que tendrá el proyecto; se usa para validar el mínimo de días.
  int get _numeroEtapas => ProyectoTaller.etapasPorDefecto(_tipo).length;

  Future<void> _seleccionarFechaEntrega(FormFieldState<DateTime> campo) async {
    final hoy = DateTime.now();
    final seleccion = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? _fechaInspeccion.add(Duration(days: _numeroEtapas + 3)),
      firstDate: _fechaInspeccion,
      lastDate: DateTime(hoy.year + 2),
      helpText: 'Fecha de entrega a la aseguradora',
    );
    if (seleccion == null) return;
    setState(() => _fechaEntrega = seleccion);
    campo.didChange(seleccion);
  }

  void _quitarRefaccion(int index) {
    final quitada = _refacciones[index];
    setState(() => _refacciones.removeAt(index));
    // Se libera después del cuadro actual, cuando el campo ya no está en pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) => quitada.nombre.dispose());
  }

  void _agregarDano(String dano) {
    final actual = _descripcionCtrl.text.trim();
    if (actual.contains(dano)) return;
    _descripcionCtrl.text = actual.isEmpty ? '• $dano' : '$actual\n• $dano';
  }

  Future<void> _guardar() async {
    if (_guardando) return;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los campos marcados en rojo.'), backgroundColor: AppTheme.danger),
      );
      return;
    }

    final bool esAseguradora = _tipo == TipoProyecto.aseguradora;
    // Los días disponibles se reparten entre las etapas sugeridas (se pueden ajustar después)
    final int diasDisponibles = esAseguradora
        ? ProyectoTaller.diasEntre(_fechaInspeccion, _fechaEntrega!)
        : int.parse(_diasCtrl.text);
    final etapas = ProyectoTaller.repartirDias(ProyectoTaller.etapasPorDefecto(_tipo), diasDisponibles);
    final proyecto = ProyectoTaller(
      id: _store.siguienteId(_tipo),
      tipo: _tipo,
      nombreCamion: _camionCtrl.text.trim(),
      placa: _placaCtrl.text.trim(),
      cliente: esAseguradora ? '' : _clienteCtrl.text.trim(),
      responsable: _responsableCtrl.text.trim(),
      aseguradora: esAseguradora ? _aseguradoraCtrl.text.trim() : null,
      numeroSiniestro: esAseguradora && _siniestroCtrl.text.trim().isNotEmpty ? _siniestroCtrl.text.trim() : null,
      fechaEntregaComprometida: esAseguradora ? _fechaEntrega : null,
      fechaIngreso: _fechaInspeccion,
      etapas: etapas,
      // La evaluación ya se hizo: el proyecto arranca en la etapa siguiente
      etapaActual: etapas.length > 1 ? 1 : 0,
      fechaEvaluacion: _fechaInspeccion,
      descripcionDanos: _descripcionCtrl.text.trim(),
      refaccionesCotizadas: [
        for (final r in _refacciones)
          if (r.nombre.text.trim().isNotEmpty) RefaccionCotizada(nombre: r.nombre.text.trim(), cantidad: r.cantidad),
      ],
      fotos: List.of(_fotos),
    );
    setState(() => _guardando = true);
    final resultado = await _store.crear(proyecto);
    if (!mounted) return;
    setState(() => _guardando = false);

    final creado = resultado.proyecto;
    if (creado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado.error ?? 'No se pudo crear el proyecto.'), backgroundColor: AppTheme.danger),
      );
      return;
    }
    _guardado = true; // las fotos ya pertenecen al proyecto

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DetalleProyectoScreen(proyecto: creado)));
    messenger.showSnackBar(
      SnackBar(
        content: Text(resultado.error ?? 'Evaluación guardada. Proyecto ${creado.id} creado.'),
        backgroundColor: resultado.error == null ? AppTheme.success : AppTheme.warning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: widget.tipo == null ? const MenuLateral(seccion: Seccion.evaluacion) : null,
      appBar: AppBar(title: const Text('Evaluación de Daños')),
      body: ContenidoResponsivo(
        anchoMaximo: 760,
        // Solo quien puede crear proyectos llena la evaluación (Admin, Proyectos y Evaluación)
        child: !Sesion.creaProyectos
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: AvisoSoloLectura(
                    'Tu perfil no puede registrar evaluaciones. Consulta las evaluaciones en el detalle de cada proyecto.'),
              )
            : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _buildPasos(),
              const SizedBox(height: 16),
              _seccion(
                titulo: 'Datos de la unidad',
                children: [
                  if (widget.tipo == null) ...[
                    _etiqueta('Tipo de proyecto *'),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<TipoProyecto>(
                        segments: const [
                          ButtonSegment(value: TipoProyecto.cliente, icon: Icon(Icons.person_outline), label: Text('Cliente')),
                          ButtonSegment(value: TipoProyecto.aseguradora, icon: Icon(Icons.verified_user_outlined), label: Text('Aseguradora')),
                        ],
                        selected: {_tipo},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) => setState(() => _tipo = s.first),
                      ),
                    ),
                  ] else
                    Text(
                      'Se creará en ${_tipo.titulo}.',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  _etiqueta('Nombre del camión *'),
                  TextFormField(
                    controller: _camionCtrl,
                    validator: _requerido('Ingresa el nombre del camión'),
                    decoration: AppTheme.inputDecoration('Ej. Kenworth T680 2021', icon: Icons.local_shipping_outlined),
                  ),
                  _etiqueta('Placa *'),
                  TextFormField(
                    controller: _placaCtrl,
                    inputFormatters: formateadoresPlaca,
                    validator: _requerido('Ingresa la placa'),
                    decoration: AppTheme.inputDecoration('Ej. DUR-4821', icon: Icons.pin_outlined),
                  ),
                  if (_tipo == TipoProyecto.cliente) ...[
                    _etiqueta('Cliente *'),
                    TextFormField(
                      controller: _clienteCtrl,
                      validator: _requerido('Ingresa el cliente'),
                      decoration: AppTheme.inputDecoration('Nombre o empresa del cliente', icon: Icons.person_outline),
                    ),
                  ] else ...[
                    _etiqueta('Aseguradora *'),
                    TextFormField(
                      controller: _aseguradoraCtrl,
                      validator: _requerido('Ingresa la aseguradora'),
                      decoration: AppTheme.inputDecoration('Ej. Seguros Atlas', icon: Icons.verified_user_outlined),
                    ),
                    _etiqueta('Número de siniestro'),
                    TextFormField(
                      controller: _siniestroCtrl,
                      inputFormatters: [MayusculasFormatter()],
                      decoration: AppTheme.inputDecoration('Opcional', icon: Icons.confirmation_number_outlined),
                    ),
                  ],
                  _etiqueta('Responsable'),
                  TextFormField(
                    controller: _responsableCtrl,
                    decoration: AppTheme.inputDecoration('Opcional', icon: Icons.engineering_outlined),
                  ),
                  _etiqueta('Fecha de inspección *'),
                  InkWell(
                    onTap: _seleccionarFecha,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: AppTheme.inputDecoration('Fecha', icon: Icons.calendar_today),
                      child: Text(formatearFecha(_fechaInspeccion)),
                    ),
                  ),
                  if (_tipo == TipoProyecto.cliente) ..._buildDiasEstimados() else ..._buildFechaEntrega(),
                ],
              ),
              const SizedBox(height: 20),
              _seccion(
                titulo: 'Diagnóstico de daños',
                children: [
                  const Text('Toca los hallazgos comunes para agregarlos:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final dano in _danosComunes)
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(dano, style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.grey.shade50,
                          side: const BorderSide(color: AppTheme.border),
                          onPressed: () => _agregarDano(dano),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 5,
                    validator: _requerido('Describe los daños observados'),
                    decoration: AppTheme.inputDecoration('Describe los daños de la unidad...'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _seccion(
                titulo: 'Fotos de la unidad',
                contador: '${_fotos.length}',
                children: [
                  GaleriaFotos(
                    fotos: _fotos,
                    onAgregada: (ruta) => setState(() => _fotos.add(ruta)),
                    onQuitada: (ruta) {
                      setState(() => _fotos.remove(ruta));
                      FotosService.borrar(ruta);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _seccion(
                titulo: 'Cotización de refacciones',
                contador: '${_refacciones.length} ítems',
                children: [
                  for (int i = 0; i < _refacciones.length; i++) ...[
                    if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Refacción #${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                        ),
                        if (_refacciones.length > 1)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger, size: 20),
                            tooltip: 'Quitar',
                            onPressed: () => _quitarRefaccion(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: ObjectKey(_refacciones[i].nombre),
                      controller: _refacciones[i].nombre,
                      decoration: AppTheme.inputDecoration('Nombre de la pieza (opcional)', icon: Icons.build_circle_outlined),
                    ),
                    const SizedBox(height: 10),
                    SafeNumberPicker(
                      key: ObjectKey(_refacciones[i]),
                      label: 'Cantidad requerida',
                      value: _refacciones[i].cantidad,
                      min: 1,
                      max: 100,
                      unit: 'uds.',
                      onChanged: (n) => setState(() => _refacciones[i].cantidad = n),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _refacciones.add(_RefaccionEditable())),
                      icon: const Icon(Icons.add, color: AppTheme.primary, size: 18),
                      label: const Text('Añadir otra refacción', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardar,
                  icon: _guardando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined, color: Colors.white),
                  label: const Text('Guardar evaluación y crear proyecto',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Las etapas del proyecto se pueden ajustar después desde el detalle del proyecto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cliente: lapso de días estimados para la reparación.
  List<Widget> _buildDiasEstimados() {
    final dias = int.tryParse(_diasCtrl.text);
    return [
      _etiqueta('Días estimados *'),
      TextFormField(
        key: const Key('campo-dias-estimados'),
        controller: _diasCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
        onChanged: (_) => setState(() {}),
        validator: (v) {
          final n = int.tryParse(v ?? '');
          if (n == null) return 'Ingresa los días estimados';
          if (n < _numeroEtapas) return 'Mínimo $_numeroEtapas días (uno por etapa)';
          return null;
        },
        decoration: AppTheme.inputDecoration('Ej. 10', icon: Icons.schedule).copyWith(suffixText: 'días'),
      ),
      if (dias != null && dias > 0) ...[
        const SizedBox(height: 6),
        Text(
          'Entrega estimada: ${formatearFecha(_fechaInspeccion.add(Duration(days: dias)))}',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ];
  }

  /// Aseguradora: fecha de entrega comprometida (no estimada).
  List<Widget> _buildFechaEntrega() {
    return [
      _etiqueta('Fecha de entrega *'),
      FormField<DateTime>(
        // Se reconstruye si cambia la fecha de inspección, para volver a validar contra ella
        key: ValueKey('entrega-${_fechaInspeccion.toIso8601String()}'),
        initialValue: _fechaEntrega,
        validator: (v) {
          if (v == null) return 'Elige la fecha de entrega comprometida';
          if (ProyectoTaller.diasEntre(_fechaInspeccion, v) < _numeroEtapas) {
            return 'Debe ser al menos $_numeroEtapas días después de la inspección (uno por etapa)';
          }
          return null;
        },
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
      const SizedBox(height: 6),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 16, color: AppTheme.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _fechaEntrega == null
                  ? 'Fecha comprometida con la aseguradora: si no se entrega ese día, hay multa.'
                  : 'Fecha comprometida (${ProyectoTaller.diasEntre(_fechaInspeccion, _fechaEntrega!)} días). Si no se entrega ese día, la aseguradora multa.',
              style: const TextStyle(color: AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ];
  }

  /// Indicador de que la evaluación es el paso 1 y el proyecto el paso 2.
  Widget _buildPasos() {
    Widget paso(String numero, String texto, bool activo) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: activo ? AppTheme.primary : AppTheme.border,
              child: Text(numero, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activo ? Colors.white : AppTheme.textSecondary)),
            ),
            const SizedBox(width: 6),
            Text(texto, style: TextStyle(fontSize: 12, fontWeight: activo ? FontWeight.bold : FontWeight.normal)),
          ],
        );

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        paso('1', 'Evaluar el daño', true),
        const Icon(Icons.arrow_forward, size: 16, color: AppTheme.textMuted),
        paso('2', 'Se crea el proyecto', false),
      ],
    );
  }

  FormFieldValidator<String> _requerido(String mensaje) => (v) => (v == null || v.trim().isEmpty) ? mensaje : null;

  Widget _etiqueta(String texto) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
      );

  Widget _seccion({required String titulo, String? contador, required List<Widget> children}) {
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
              if (contador != null)
                Text(contador, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
