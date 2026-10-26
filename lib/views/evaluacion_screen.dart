import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/safe_number_picker.dart';

class EvaluacionScreen extends StatefulWidget {
  const EvaluacionScreen({super.key});

  @override
  State<EvaluacionScreen> createState() => _EvaluacionScreenState();
}

class _EvaluacionScreenState extends State<EvaluacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  static const List<String> _camionesDisponibles = [
    'Camión 01 - Volvo 2019 (Transportes del Norte)',
    'Camión 02 - Kenworth T680 (Logística Express)',
    'Camión 03 - Freightliner Cascadia (Grupo Modelo)',
    'Camión 04 - International ProStar (Fletes del Bajío)',
  ];

  static const List<String> _danosComunes = [
    'Falla en embrague',
    'Fuga de fluido de frenos',
    'Desalineación de chasis',
    'Filtro obstruido',
    'Amortiguador reventado',
    'Golpe en cabina / pintura',
  ];

  String _camionSeleccionado = _camionesDisponibles.first;

  // Lista dinámica de materiales para cotización con cantidades protegidas
  final List<Map<String, dynamic>> _cotizacionItems = [];

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _fechaController.text = "${hoy.day}/${hoy.month}/${hoy.year}";
    _agregarElementoCotizacion();
  }

  void _agregarElementoCotizacion() {
    setState(() {
      _cotizacionItems.add({
        'controlador': TextEditingController(text: 'Kit de Balatas Cerámicas'),
        'cantidad': 1,
      });
    });
  }

  void _removerElementoCotizacion(int index) {
    if (_cotizacionItems.length > 1) {
      setState(() {
        _cotizacionItems[index]['controlador'].dispose();
        _cotizacionItems.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe existir al menos un elemento en la cotización.')),
      );
    }
  }

  Future<void> _seleccionarFecha(BuildContext context) async {
    final DateTime? seleccion = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (seleccion != null) {
      setState(() {
        _fechaController.text = "${seleccion.day}/${seleccion.month}/${seleccion.year}";
      });
    }
  }

  void _agregarDanoChip(String dano) {
    final actual = _descripcionController.text.trim();
    if (actual.isEmpty) {
      _descripcionController.text = '• $dano';
    } else if (!actual.contains(dano)) {
      _descripcionController.text = '$actual\n• $dano';
    }
  }

  void _guardarEvaluacion() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Evaluación guardada exitosamente para "$_camionSeleccionado".'),
        backgroundColor: AppTheme.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _descripcionController.dispose();
    for (var item in _cotizacionItems) {
      item['controlador']?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Evaluación de Daños'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Datos Generales de Ingreso
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppTheme.cardShadow,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Datos de la Unidad *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 14),

                    // Selector controlado de camión
                    const Text('Unidad / Camión Ingresado', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _camionSeleccionado,
                      isExpanded: true,
                      decoration: AppTheme.inputDecoration('Selecciona la unidad', icon: Icons.local_shipping_outlined),
                      items: _camionesDisponibles.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _camionSeleccionado = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Fecha gobernada por calendario
                    const Text('Fecha de Inspección *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fechaController,
                      readOnly: true,
                      onTap: () => _seleccionarFecha(context),
                      decoration: AppTheme.inputDecoration(
                        'Selecciona fecha',
                        icon: Icons.calendar_today,
                        helperText: 'El usuario no puede ingresar fechas inválidas manualmente.',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Diagnóstico con Chips Rápidos a prueba de olvidos
                    const Text('Diagnóstico de Daños Detectados *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Toca los hallazgos comunes para insertarlos de inmediato:', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _danosComunes.map((dano) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(dano, style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.grey.shade50,
                          side: const BorderSide(color: AppTheme.border),
                          onPressed: () => _agregarDanoChip(dano),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 4,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Describe los daños observados en la unidad.';
                        return null;
                      },
                      decoration: AppTheme.inputDecoration('Detalla las anomalías o usa las etiquetas rápidas...'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Cotización con Cantidades Protegidas (Safe Number Picker)
              Container(
                padding: const EdgeInsets.all(22),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Cotización de Refacciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${_cotizacionItems.length} ítems', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _cotizacionItems.length,
                      separatorBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      itemBuilder: (context, index) {
                        final item = _cotizacionItems[index];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('Ítem #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                                const Spacer(),
                                if (_cotizacionItems.length > 1)
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.danger, size: 20),
                                    tooltip: 'Quitar ítem',
                                    onPressed: () => _removerElementoCotizacion(index),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: item['controlador'],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Ingresa la refacción necesaria';
                                return null;
                              },
                              decoration: AppTheme.inputDecoration('Nombre de la pieza o componente', icon: Icons.build_circle_outlined),
                            ),
                            const SizedBox(height: 10),
                            SafeNumberPicker(
                              label: 'Cantidad Requerida',
                              value: item['cantidad'] as int,
                              min: 1,
                              max: 100,
                              unit: 'uds.',
                              quickSteps: const [1, 2, 5],
                              onChanged: (nuevaCant) {
                                setState(() {
                                  item['cantidad'] = nuevaCant;
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Botón para agregar más refacciones
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _agregarElementoCotizacion,
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
              ),
              const SizedBox(height: 32),

              // Botón Guardar Evaluación
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _guardarEvaluacion,
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label: const Text('Guardar Evaluación e Iniciar Proyecto', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}