import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/safe_number_picker.dart';

class DepartamentosScreen extends StatefulWidget {
  const DepartamentosScreen({super.key});

  @override
  State<DepartamentosScreen> createState() => _DepartamentosScreenState();
}

class _DepartamentosScreenState extends State<DepartamentosScreen> {
  final List<Map<String, dynamic>> _departamentos = [
    {'id': 'DEP-01', 'nombre': 'Almacén General', 'encargado': 'Gabriela Gómez', 'empleados': 3, 'icono': Icons.inventory_2},
    {'id': 'DEP-02', 'nombre': 'Soldadura y Chasis', 'encargado': 'Sergio Urey Morales', 'empleados': 5, 'icono': Icons.handyman},
    {'id': 'DEP-03', 'nombre': 'Pintura y Estética', 'encargado': 'Carlos Martínez', 'empleados': 4, 'icono': Icons.format_paint},
    {'id': 'DEP-04', 'nombre': 'Mecánica Diésel', 'encargado': 'Roberto Gómez', 'empleados': 6, 'icono': Icons.settings},
  ];

  static const List<String> _encargadosDisponibles = [
    'Gabriela Gómez',
    'Sergio Urey Morales',
    'Carlos Martínez',
    'Roberto Gómez',
    'Ing. Carlos Mendoza',
  ];

  void _mostrarModalNuevoDepartamento() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    String encargadoSel = _encargadosDisponibles.first;
    IconData iconoSel = Icons.build;
    int empleadosSel = 1;

    final List<IconData> iconosOpciones = [
      Icons.inventory_2,
      Icons.handyman,
      Icons.format_paint,
      Icons.settings,
      Icons.electric_meter,
      Icons.local_shipping,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nuevo Departamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      const Text('Nombre del Área / Departamento *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nombreCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre del área' : null,
                        decoration: AppTheme.inputDecoration('Ej. Diagnóstico Electrónico'),
                      ),
                      const SizedBox(height: 14),

                      const Text('Encargado Designado *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: encargadoSel,
                        decoration: AppTheme.inputDecoration('Selecciona encargado'),
                        items: _encargadosDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => encargadoSel = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      const Text('Ícono Representativo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: iconosOpciones.map((ico) {
                          final bool sel = iconoSel == ico;
                          return InkWell(
                            onTap: () => setModalState(() => iconoSel = ico),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: sel ? AppTheme.primary : AppTheme.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: sel ? AppTheme.primary : AppTheme.border),
                              ),
                              child: Icon(ico, color: sel ? Colors.white : AppTheme.textPrimary, size: 22),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      SafeNumberPicker(
                        label: 'Personal Asignado Inicial',
                        value: empleadosSel,
                        min: 0,
                        max: 50,
                        unit: 'empleados',
                        onChanged: (nuevaCant) {
                          setModalState(() => empleadosSel = nuevaCant);
                        },
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (!formKey.currentState!.validate()) return;
                            setState(() {
                              _departamentos.add({
                                'id': 'DEP-0${_departamentos.length + 1}',
                                'nombre': nombreCtrl.text.trim(),
                                'encargado': encargadoSel,
                                'empleados': empleadosSel,
                                'icono': iconoSel,
                              });
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Departamento "${nombreCtrl.text.trim()}" creado exitosamente.'),
                                backgroundColor: AppTheme.success,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Guardar Departamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _eliminarDepartamento(Map<String, dynamic> depto) async {
    final bool confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar Departamento',
      message: '¿Estás seguro de que deseas eliminar el área "${depto['nombre']}"? Los empleados asignados deberán ser reubicados.',
      confirmText: 'Sí, Eliminar',
      isDestructive: true,
      icon: Icons.domain_disabled_rounded,
    );

    if (confirmar) {
      setState(() {
        _departamentos.removeWhere((d) => d['id'] == depto['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Departamento "${depto['nombre']}" eliminado.'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Gestión de Departamentos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Áreas Operativas del Taller', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('${_departamentos.length} activas', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),

            Expanded(
              child: ListView.builder(
                itemCount: _departamentos.length,
                itemBuilder: (context, index) {
                  final depto = _departamentos[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
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
                          decoration: BoxDecoration(color: const Color(0xFFF1F2F4), shape: BoxShape.circle),
                          child: Icon(depto['icono'] as IconData, color: AppTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(depto['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Encargado: ${depto['encargado']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text('${depto['empleados']}', style: const TextStyle(color: AppTheme.info, fontWeight: FontWeight.bold, fontSize: 15)),
                              const Text('Personal', style: TextStyle(color: AppTheme.info, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
                          tooltip: 'Eliminar área',
                          onPressed: () => _eliminarDepartamento(depto),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Botón añadir
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _mostrarModalNuevoDepartamento,
                icon: const Icon(Icons.add_business_outlined, color: Colors.white),
                label: const Text('Añadir Nuevo Departamento', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}