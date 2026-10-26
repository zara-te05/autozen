import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/status_badge.dart';

class DetalleProyectoScreen extends StatefulWidget {
  final String nombreProyecto;
  final String cliente;
  final int etapaActual;
  final String? responsable;
  final ValueChanged<int>? onEtapaUpdated;

  const DetalleProyectoScreen({
    super.key,
    required this.nombreProyecto,
    required this.cliente,
    this.etapaActual = 1,
    this.responsable,
    this.onEtapaUpdated,
  });

  @override
  State<DetalleProyectoScreen> createState() => _DetalleProyectoScreenState();
}

class _DetalleProyectoScreenState extends State<DetalleProyectoScreen> {
  late int _etapa;

  static const List<String> _etapasTexto = [
    'Evaluación Inicial',
    'Suministro de Refacciones',
    'Reparación y Pintura',
    'Unidad Terminada / Listo',
  ];

  final List<Map<String, dynamic>> _tareas = [
    {'titulo': 'Inspección de daños estructurales en chasis', 'completado': true},
    {'titulo': 'Desmontaje de componentes afectados', 'completado': true},
    {'titulo': 'Soldadura especializada en soporte de eje', 'completado': false},
    {'titulo': 'Instalación de kit de embrague y filtros', 'completado': false},
    {'titulo': 'Pruebas de frenos y pulido de pintura', 'completado': false},
  ];

  @override
  void initState() {
    super.initState();
    _etapa = widget.etapaActual;
  }

  double get _progreso {
    if (_tareas.isEmpty) return 0.0;
    int completadas = _tareas.where((t) => t['completado'] == true).length;
    return completadas / _tareas.length;
  }

  Future<void> _avanzarEtapa() async {
    if (_etapa >= 3) return;

    final String siguienteEtapa = _etapasTexto[_etapa + 1];

    final bool confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Avanzar Etapa de Trabajo',
      message: '¿Confirmas que la fase actual concluyó y deseas promover la unidad a "$siguienteEtapa"? El cambio quedará registrado en bitácora.',
      confirmText: 'Sí, Avanzar',
      icon: Icons.fast_forward_rounded,
    );

    if (confirmar) {
      setState(() {
        _etapa++;
      });
      widget.onEtapaUpdated?.call(_etapa);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unidad promovida exitosamente a "$siguienteEtapa".'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double progresoVal = _progreso;
    final int pct = (progresoVal * 100).toInt();

    BadgeType badgeType = BadgeType.info;
    if (_etapa == 0) badgeType = BadgeType.warning;
    if (_etapa == 2) badgeType = BadgeType.warning;
    if (_etapa == 3) badgeType = BadgeType.success;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detalle de Unidad'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Cabecera del Camión
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(
                            label: _etapasTexto[_etapa].toUpperCase(),
                            type: badgeType,
                          ),
                          Text(
                            'Etapa ${_etapa + 1} de 4',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        widget.nombreProyecto,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cliente: ${widget.cliente}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Transición Controlada de Etapa (Foolproof Guardrail)
                Container(
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
                      const Text(
                        'Control Secuencial de Etapa',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _etapa < 3
                            ? 'Para evitar saltos erráticos, el avance se realiza paso a paso de forma gobernada.'
                            : 'Esta unidad ha finalizado todas las fases de reparación en el taller.',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _etapa < 3 ? _avanzarEtapa : null,
                          icon: Icon(
                            _etapa < 3 ? Icons.arrow_circle_right_outlined : Icons.check_circle,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: Text(
                            _etapa < 3
                                ? 'Avanzar a: ${_etapasTexto[_etapa + 1]}'
                                : 'Proyecto Terminado y Liberado',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _etapa < 3 ? AppTheme.primary : AppTheme.success,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Encargado Asignado
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.engineering_outlined, color: AppTheme.info),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.responsable ?? 'Sergio Urey Morales',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const Text(
                              'Especialista Técnico Responsable',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Checklist de Tareas con Cálculo Automático de Avance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Checklist de Tareas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      '$pct% completado',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progresoVal,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tareas.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tarea = _tareas[index];
                      final bool done = tarea['completado'] as bool;

                      return CheckboxListTile(
                        value: done,
                        activeColor: AppTheme.primary,
                        title: Text(
                          tarea['titulo'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: done ? FontWeight.normal : FontWeight.w600,
                            color: done ? AppTheme.textMuted : AppTheme.textPrimary,
                            decoration: done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        onChanged: (bool? val) {
                          setState(() {
                            tarea['completado'] = val ?? false;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 5. Botón inferior fijo de Solicitud Rápida
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Solicitud de refacciones abierta para ${widget.nombreProyecto}.'),
                      backgroundColor: Colors.black87,
                    ),
                  );
                },
                icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
                label: const Text('Solicitar Refacciones a Almacén', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}