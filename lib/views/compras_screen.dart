import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/safe_number_picker.dart';
import '../widgets/status_badge.dart';

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _ordenes = [
    {
      'id': 'OC-2026-001',
      'camion': 'Camión 01 - Volvo 2019',
      'proveedor': 'Refacciones Diésel del Norte',
      'piezas': 'Kit de Embrague, Sensores',
      'cantidad': 3,
      'costo': 12450.0,
      'fecha_actual': '15/Oct/2026',
      'fecha_entrega': '18/Oct/2026',
      'retrasado': false,
    },
    {
      'id': 'OC-2026-002',
      'camion': 'Camión 02 - Kenworth T680',
      'proveedor': 'Frenos y Balatas de México',
      'piezas': 'Compresor de Aire Wabco',
      'cantidad': 1,
      'costo': 8200.0,
      'fecha_actual': '10/Oct/2026',
      'fecha_entrega': '14/Oct/2026',
      'retrasado': true,
    },
    {
      'id': 'OC-2026-003',
      'camion': 'Camión 03 - Freightliner Cascadia',
      'proveedor': 'Aceites y Lubricantes Industriales',
      'piezas': 'Tambor de Aceite 15W40 (200L)',
      'cantidad': 1,
      'costo': 14800.0,
      'fecha_actual': '14/Oct/2026',
      'fecha_entrega': '20/Oct/2026',
      'retrasado': false,
    },
  ];

  static const List<String> _proveedoresValidos = [
    'Refacciones Diésel del Norte',
    'Frenos y Balatas de México',
    'Aceites y Lubricantes Industriales',
    'Tornillería y Autopartes del Bajío',
  ];

  static const List<String> _camionesValidos = [
    'Camión 01 - Volvo 2019',
    'Camión 02 - Kenworth T680',
    'Camión 03 - Freightliner Cascadia',
    'Stock de Almacén General',
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _mostrarModalNuevaOrden() {
    String camionSel = _camionesValidos.first;
    String provSel = _proveedoresValidos.first;
    final piezaCtrl = TextEditingController(text: 'Amortiguadores Traseros');
    final costoCtrl = TextEditingController(text: '3200.00');
    int cantSel = 2;
    double costoSel = 3200.0;
    final formKey = GlobalKey<FormState>();

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
                          const Text('Nueva Orden de Compra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Camión destino controlado
                      const Text('Unidad / Destino *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: camionSel,
                        decoration: AppTheme.inputDecoration('Selecciona camión'),
                        items: _camionesValidos.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => camionSel = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Proveedor verificado
                      const Text('Proveedor Autorizado *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: provSel,
                        decoration: AppTheme.inputDecoration('Selecciona proveedor'),
                        items: _proveedoresValidos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => provSel = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Descripción de piezas
                      const Text('Piezas Solicitadas *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: piezaCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa la refacción' : null,
                        decoration: AppTheme.inputDecoration('Ej. 2 Discos y Pastillas de Freno'),
                      ),
                      const SizedBox(height: 14),

                      // Stepper seguro de cantidad
                      SafeNumberPicker(
                        label: 'Cantidad a Adquirir',
                        value: cantSel,
                        min: 1,
                        max: 100,
                        unit: 'uds.',
                        onChanged: (nuevo) {
                          setModalState(() => cantSel = nuevo);
                        },
                      ),
                      const SizedBox(height: 14),

                      // Costo unitario
                      const Text('Costo Estimado Unitario (\$)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: costoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: AppTheme.inputDecoration('0.00', icon: Icons.attach_money),
                        onChanged: (val) {
                          costoSel = double.tryParse(val) ?? 0.0;
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
                              _ordenes.insert(0, {
                                'id': 'OC-2026-00${_ordenes.length + 1}',
                                'camion': camionSel,
                                'proveedor': provSel,
                                'piezas': piezaCtrl.text.trim(),
                                'cantidad': cantSel,
                                'costo': costoSel,
                                'fecha_actual': '25/Oct/2026',
                                'fecha_entrega': '28/Oct/2026',
                                'retrasado': false,
                              });
                            });
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Orden de compra registrada con éxito.')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Generar Orden de Compra', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Gestión de Compras'),
        bottom: TabBar(
          controller: _tabController,
          tabAlignment: TabAlignment.center,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Reportes por Unidad'),
            Tab(text: 'Análisis Financiero'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalNuevaOrden,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text('Nueva Orden', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabReportes(context),
          _buildTabAnalisis(context),
        ],
      ),
    );
  }

  Widget _buildTabReportes(BuildContext context) {
    final filtradas = _ordenes.where((o) {
      final q = _searchQuery.toLowerCase();
      return o['camion'].toString().toLowerCase().contains(q) ||
          o['id'].toString().toLowerCase().contains(q) ||
          o['proveedor'].toString().toLowerCase().contains(q) ||
          o['piezas'].toString().toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Buscador controlado
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: AppTheme.inputDecoration(
              'Buscar por orden, camión, refacción...',
              icon: Icons.search,
              suffix: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: filtradas.isEmpty
                ? const Center(child: Text('No hay órdenes registradas con ese criterio.'))
                : ListView.builder(
                    itemCount: filtradas.length,
                    itemBuilder: (context, index) {
                      final orden = filtradas[index];
                      final bool retrasado = orden['retrasado'] as bool;
                      final double costo = orden['costo'] as double;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: AppTheme.cardShadow,
                          border: Border.all(
                            color: retrasado ? AppTheme.danger.withValues(alpha: 0.4) : AppTheme.border,
                            width: retrasado ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F2F4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.receipt_long, size: 20, color: AppTheme.primary),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(orden['camion'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        Text('${orden['id']} • ${orden['proveedor']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                                StatusBadge(
                                  label: retrasado ? 'RETRASADO' : 'EN TIEMPO',
                                  type: retrasado ? BadgeType.danger : BadgeType.success,
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            Text('Piezas: ${orden['piezas']} (${orden['cantidad']} uds.)', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Entrega: ${orden['fecha_entrega']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                Text('\$ ${costo.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabAnalisis(BuildContext context) {
    final double totalGastado = _ordenes.fold(0.0, (acc, o) => acc + (o['costo'] as double));
    final int retrasadas = _ordenes.where((o) => o['retrasado'] == true).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gasto Total en Refacciones', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('\$ ${totalGastado.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total de ${_ordenes.length} órdenes generadas', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('A Tiempo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('${_ordenes.length - retrasadas}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.success)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Retrasos Críticos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('$retrasadas', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.danger)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}