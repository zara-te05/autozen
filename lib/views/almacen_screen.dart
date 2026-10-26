import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlmacenScreen extends StatefulWidget {
  const AlmacenScreen({super.key});

  @override
  State<AlmacenScreen> createState() => _AlmacenScreenState();
}

class _AlmacenScreenState extends State<AlmacenScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ----------------------------------------------------
  // DATOS DEL INVENTARIO (Catálogo de piezas del almacén)
  // ----------------------------------------------------
  final List<Map<String, dynamic>> _inventario = [
    {
      'id': 'ALM-001',
      'nombre': 'Balatas de freno cerámicas',
      'categoria': 'Frenos',
      'cantidad': 14,
      'costo': 1250.0,
      'ubicacion': 'Estante B-2',
    },
    {
      'id': 'ALM-002',
      'nombre': 'Aceite de Motor Sintético 15W40 (Lts)',
      'categoria': 'Fluidos',
      'cantidad': 50,
      'costo': 320.0,
      'ubicacion': 'Zona C-1',
    },
    {
      'id': 'ALM-003',
      'nombre': 'Filtro de Aire Kenworth T680',
      'categoria': 'Motor',
      'cantidad': 3,
      'costo': 890.0,
      'ubicacion': 'Estante A-4',
    },
    {
      'id': 'ALM-004',
      'nombre': 'Kit de Embrague Reforzado',
      'categoria': 'Transmisión',
      'cantidad': 2,
      'costo': 8400.0,
      'ubicacion': 'Pasillo 1',
    },
    {
      'id': 'ALM-005',
      'nombre': 'Amortiguador Delantero Volvo FH',
      'categoria': 'Suspensión',
      'cantidad': 0,
      'costo': 3100.0,
      'ubicacion': 'Estante D-1',
    },
    {
      'id': 'ALM-006',
      'nombre': 'Sensor de Presión de Riel Diésel',
      'categoria': 'Eléctrico',
      'cantidad': 8,
      'costo': 1650.0,
      'ubicacion': 'Gaveta E-3',
    },
    {
      'id': 'ALM-007',
      'nombre': 'Faro Principal LED Delantero',
      'categoria': 'Carrocería',
      'cantidad': 4,
      'costo': 4200.0,
      'ubicacion': 'Estante F-2',
    },
  ];

  // ----------------------------------------------------
  // CONTROLADORES PARA ALTA DE PIEZAS
  // ----------------------------------------------------
  final _formKeyAlta = GlobalKey<FormState>();
  final TextEditingController _nombrePiezaController = TextEditingController();
  final TextEditingController _codigoPiezaController = TextEditingController(text: 'ALM-008');
  final TextEditingController _ubicacionPiezaController = TextEditingController();
  final TextEditingController _cantidadAltaController = TextEditingController(text: '1');
  final TextEditingController _costoAltaController = TextEditingController(text: '0.00');
  
  int _cantidadAlta = 1;
  double _costoAlta = 0.0;
  String _categoriaSeleccionada = 'Frenos';
  final List<String> _categorias = [
    'Frenos',
    'Motor',
    'Transmisión',
    'Suspensión',
    'Eléctrico',
    'Fluidos',
    'Carrocería',
    'Herramientas',
  ];

  // ----------------------------------------------------
  // ESTADOS DEL DATAGRID (Ordenamiento, Filtros y Vista)
  // ----------------------------------------------------
  final TextEditingController _searchGridController = TextEditingController();
  String _searchQuery = '';
  String _filtroEstado = 'Todos'; // 'Todos', 'En Stock', 'Bajo Stock', 'Agotado'
  int _sortColumnIndex = 3; // Por defecto ordenar por Stock
  bool _sortAscending = true;
  bool _isTableView = true; // true: DataGrid tabular, false: Vista tarjetas compactas

  // ----------------------------------------------------
  // CONTROLADORES PARA VALES DE SALIDA
  // ----------------------------------------------------
  final TextEditingController _horaExtraccionController = TextEditingController();
  final TextEditingController _horaDevolucionController = TextEditingController();
  final TextEditingController _proyectoDestinoController = TextEditingController();
  String? _piezaValeSeleccionada;
  int _cantidadVale = 1;
  final TextEditingController _cantidadValeController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final ahora = TimeOfDay.now();
    _horaExtraccionController.text = "${ahora.hour}:${ahora.minute.toString().padLeft(2, '0')}";
    _piezaValeSeleccionada = _inventario.first['nombre'];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombrePiezaController.dispose();
    _codigoPiezaController.dispose();
    _ubicacionPiezaController.dispose();
    _cantidadAltaController.dispose();
    _costoAltaController.dispose();
    _searchGridController.dispose();
    _horaExtraccionController.dispose();
    _horaDevolucionController.dispose();
    _proyectoDestinoController.dispose();
    _cantidadValeController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------
  // LOGICA PARA ALTA DE PIEZAS
  // ----------------------------------------------------
  void _guardarNuevaPieza() {
    if (!_formKeyAlta.currentState!.validate()) return;

    final String nombre = _nombrePiezaController.text.trim();
    final String codigo = _codigoPiezaController.text.trim().isEmpty 
        ? 'ALM-${(_inventario.length + 1).toString().padLeft(3, '0')}' 
        : _codigoPiezaController.text.trim();
    final String ubicacion = _ubicacionPiezaController.text.trim().isEmpty 
        ? 'Almacén Central' 
        : _ubicacionPiezaController.text.trim();

    setState(() {
      _inventario.insert(0, {
        'id': codigo,
        'nombre': nombre,
        'categoria': _categoriaSeleccionada,
        'cantidad': _cantidadAlta,
        'costo': _costoAlta,
        'ubicacion': ubicacion,
      });

      // Generar nuevo código sugerido y limpiar
      _nombrePiezaController.clear();
      _ubicacionPiezaController.clear();
      _cantidadAlta = 1;
      _cantidadAltaController.text = '1';
      _costoAlta = 0.0;
      _costoAltaController.text = '0.00';
      _codigoPiezaController.text = 'ALM-${(_inventario.length + 1).toString().padLeft(3, '0')}';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pieza "$nombre" registrada exitosamente en el DataGrid.'),
        backgroundColor: Colors.black87,
        action: SnackBarAction(
          label: 'Ver Desglose',
          textColor: Colors.amberAccent,
          onPressed: () {
            _tabController.animateTo(1);
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // FILTRADO Y ORDENAMIENTO DEL DATAGRID
  // ----------------------------------------------------
  List<Map<String, dynamic>> get _piezasFiltradas {
    List<Map<String, dynamic>> lista = _inventario.where((item) {
      final matchSearch = item['nombre'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['categoria'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['ubicacion'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchSearch) return false;

      final int cant = item['cantidad'] as int;
      if (_filtroEstado == 'En Stock') return cant >= 5;
      if (_filtroEstado == 'Bajo Stock') return cant > 0 && cant < 5;
      if (_filtroEstado == 'Agotado') return cant == 0;
      return true;
    }).toList();

    lista.sort((a, b) {
      dynamic valA;
      dynamic valB;

      switch (_sortColumnIndex) {
        case 0:
          valA = a['id'];
          valB = b['id'];
          break;
        case 1:
          valA = a['nombre'];
          valB = b['nombre'];
          break;
        case 2:
          valA = a['categoria'];
          valB = b['categoria'];
          break;
        case 3:
          valA = a['cantidad'];
          valB = b['cantidad'];
          break;
        case 4:
          valA = a['costo'];
          valB = b['costo'];
          break;
        case 5:
          valA = (a['cantidad'] as int) * (a['costo'] as double);
          valB = (b['cantidad'] as int) * (b['costo'] as double);
          break;
        default:
          valA = a['nombre'];
          valB = b['nombre'];
      }

      final comp = Comparable.compare(valA as Comparable, valB as Comparable);
      return _sortAscending ? comp : -comp;
    });

    return lista;
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  // Diálogo para ajustar stock de una fila del DataGrid
  void _mostrarDialogoAjustarStock(Map<String, dynamic> item) {
    int stockAjuste = item['cantidad'] as int;
    final stockController = TextEditingController(text: stockAjuste.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.tune, color: Colors.black87),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ajustar Stock: ${item['nombre']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Código: ${item['id']} • ${item['ubicacion']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 20),
                  const Text('Nuevo Stock:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  _buildStepperNumerico(
                    valor: stockAjuste,
                    controller: stockController,
                    min: 0,
                    onChanged: (nuevo) {
                      setModalState(() {
                        stockAjuste = nuevo;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      item['cantidad'] = stockAjuste;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Stock actualizado para ${item['nombre']} a $stockAjuste unidades.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Guardar Ajuste', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _seleccionarHora(BuildContext context, TextEditingController controlador) async {
    final TimeOfDay? seleccion = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (seleccion != null) {
      setState(() {
        controlador.text = "${seleccion.hour}:${seleccion.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Gestión de Almacén', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Alta de Piezas'),
            Tab(text: 'Desglose de inventario'),
            Tab(text: 'Vales de Salida'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAltaPiezas(),
          _buildDataGridInventario(),
          _buildValeSalida(context),
        ],
      ),
    );
  }

  // ================================================================
  // PESTAÑA 1: ALTA DE PIEZAS (CON RECOLECTOR DE NÚMEROS SEGURO)
  // ================================================================
  Widget _buildAltaPiezas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKeyAlta,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado de la tarjeta
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.05), shape: BoxShape.circle),
                    child: const Icon(Icons.playlist_add, color: Colors.black87, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Registro Seguro de Piezas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('Valores y stock con límites protegidos', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1),
              ),

              // Campo: Nombre de la pieza
              _buildEtiqueta('Nombre de la pieza *'),
              TextFormField(
                controller: _nombrePiezaController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Ingresa el nombre o descripción de la pieza';
                  if (val.trim().length < 3) return 'El nombre debe tener al menos 3 caracteres';
                  return null;
                },
                decoration: _buildInputDecoration('Ej. Amortiguador Trasero Reforzado', icon: Icons.handyman_outlined),
              ),
              const SizedBox(height: 18),

              // Fila: Código y Categoría
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEtiqueta('Código / SKU'),
                        TextFormField(
                          controller: _codigoPiezaController,
                          decoration: _buildInputDecoration('Ej. ALM-008', icon: Icons.qr_code),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEtiqueta('Categoría'),
                        DropdownButtonFormField<String>(
                          initialValue: _categoriaSeleccionada,
                          decoration: _buildInputDecoration('Categoría'),
                          items: _categorias.map((cat) {
                            return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _categoriaSeleccionada = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // ======================================================
              // RECOLECTOR DE NÚMEROS SEGURO PARA CANTIDAD DE PIEZAS
              // ======================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 18, color: Colors.black87),
                            const SizedBox(width: 6),
                            const Text(
                              'Cantidad a Ingresar *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: const Text('Mínimo 1', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Selector protegido contra valores negativos, letras y caracteres accidentales.',
                      style: TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                    const SizedBox(height: 14),

                    // Componente Stepper Seguro
                    _buildStepperNumerico(
                      valor: _cantidadAlta,
                      controller: _cantidadAltaController,
                      min: 1,
                      max: 9999,
                      onChanged: (nuevo) {
                        setState(() {
                          _cantidadAlta = nuevo;
                        });
                      },
                    ),

                    const SizedBox(height: 12),
                    // Botones de paso rápido (Quick Chips)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildQuickStepChip('+1', 1),
                        _buildQuickStepChip('+5', 5),
                        _buildQuickStepChip('+10', 10),
                        _buildQuickStepChip('+25', 25),
                        _buildQuickStepChip('+50', 50),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ======================================================
              // RECOLECTOR SEGURO DE PRECIO / COSTO UNITARIO
              // ======================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Costo Unitario de Adquisición',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        ),
                        Text(
                          'Valor total: \$ ${(_cantidadAlta * _costoAlta).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _costoAltaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Text('\$', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        hintText: '0.00',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _costoAlta = double.tryParse(val) ?? 0.0;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // Quick price chips
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildQuickPriceChip(r'+$100', 100),
                        _buildQuickPriceChip(r'+$500', 500),
                        _buildQuickPriceChip(r'+$1,000', 1000),
                        _buildQuickPriceChip(r'+$5,000', 5000),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Ubicación en almacén
              _buildEtiqueta('Ubicación Física en Almacén'),
              TextFormField(
                controller: _ubicacionPiezaController,
                decoration: _buildInputDecoration('Ej. Pasillo 3, Estante B-4', icon: Icons.location_on_outlined),
              ),
              const SizedBox(height: 28),

              // Botón Guardar Pieza
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _guardarNuevaPieza,
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  label: const Text('Dar de Alta en Almacén', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Componente Reutilizable: Stepper Numérico Seguro
  Widget _buildStepperNumerico({
    required int valor,
    required TextEditingController controller,
    required ValueChanged<int> onChanged,
    int min = 0,
    int max = 99999,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          // Botón Decrementar (-)
          IconButton(
            onPressed: valor > min
                ? () {
                    final nuevo = valor - 1;
                    controller.text = nuevo.toString();
                    onChanged(nuevo);
                  }
                : null,
            icon: const Icon(Icons.remove_circle_outline),
            color: Colors.black87,
            disabledColor: Colors.black12,
            iconSize: 28,
            tooltip: 'Reducir 1',
          ),

          // Caja de texto central blindada (sólo números)
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (str) {
                int parsed = int.tryParse(str) ?? min;
                if (parsed < min) parsed = min;
                if (parsed > max) parsed = max;
                onChanged(parsed);
              },
            ),
          ),

          // Botón Incrementar (+)
          IconButton(
            onPressed: valor < max
                ? () {
                    final nuevo = valor + 1;
                    controller.text = nuevo.toString();
                    onChanged(nuevo);
                  }
                : null,
            icon: const Icon(Icons.add_circle_outline),
            color: Colors.black87,
            disabledColor: Colors.black12,
            iconSize: 28,
            tooltip: 'Aumentar 1',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStepChip(String label, int add) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () {
        setState(() {
          _cantidadAlta += add;
          _cantidadAltaController.text = _cantidadAlta.toString();
        });
      },
    );
  }

  Widget _buildQuickPriceChip(String label, double add) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey.shade300),
      onPressed: () {
        setState(() {
          _costoAlta += add;
          _costoAltaController.text = _costoAlta.toStringAsFixed(2);
        });
      },
    );
  }

  // ================================================================
  // PESTAÑA 2: DATAGRID DE INVENTARIO (ESTILO WINDOWS FORMS ADAPTADO)
  // ================================================================
  Widget _buildDataGridInventario() {
    final piezas = _piezasFiltradas;
    final int totalPiezas = _inventario.length;
    final int stockTotal = _inventario.fold(0, (acc, item) => acc + (item['cantidad'] as int));
    final int bajoStock = _inventario.where((item) => (item['cantidad'] as int) > 0 && (item['cantidad'] as int) < 5).length;
    final int agotados = _inventario.where((item) => (item['cantidad'] as int) == 0).length;

    return Column(
      children: [
        // ----------------------------------------------------
        // TARJETAS DE RESUMEN EJECUTIVO (KPIs)
        // ----------------------------------------------------
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildKpiCard('Total Ítems', '$totalPiezas', Icons.inventory_2_outlined, Colors.black87),
                const SizedBox(width: 10),
                _buildKpiCard('Unidades Stock', '$stockTotal', Icons.all_inbox, Colors.blueGrey),
                const SizedBox(width: 10),
                _buildKpiCard('Stock Bajo (<5)', '$bajoStock', Icons.warning_amber_rounded, Colors.orange),
                const SizedBox(width: 10),
                _buildKpiCard('Agotados', '$agotados', Icons.highlight_off, Colors.redAccent),
              ],
            ),
          ),
        ),

        // ----------------------------------------------------
        // BARRA DE BÚSQUEDA Y CONTROL DE VISTA
        // ----------------------------------------------------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchGridController,
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar por código, nombre, categoría...',
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black54),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchGridController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón para alternar entre DataGrid y Tarjetas
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: Icon(_isTableView ? Icons.grid_view : Icons.table_chart, color: Colors.black87),
                      tooltip: _isTableView ? 'Ver en modo tarjetas' : 'Ver en modo DataGrid',
                      onPressed: () {
                        setState(() => _isTableView = !_isTableView);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Chips de filtro por estado
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterStatusChip('Todos'),
                    const SizedBox(width: 6),
                    _buildFilterStatusChip('En Stock'),
                    const SizedBox(width: 6),
                    _buildFilterStatusChip('Bajo Stock'),
                    const SizedBox(width: 6),
                    _buildFilterStatusChip('Agotado'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ----------------------------------------------------
        // CONTENEDOR PRINCIPAL: DATAGRID O TARJETAS
        // ----------------------------------------------------
        Expanded(
          child: piezas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No se encontraron piezas con ese criterio.', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                )
              : _isTableView
                  ? _buildDataGridTable(piezas)
                  : _buildCardsView(piezas),
        ),
      ],
    );
  }

  // Render del DataGrid tipo Windows Forms con scroll horizontal seguro
  Widget _buildDataGridTable(List<Map<String, dynamic>> piezas) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Barra de cabecera del DataGrid (Inspirado en WinForms DataGridView)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E1E24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.table_rows, color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Desglose de inventario (${piezas.length} registros)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Desliza ➔', style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),

          // Scroll Horizontal para acomodar todas las columnas en móviles y tablets
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: const BouncingScrollPhysics(),
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F2F4)),
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 58,
                  horizontalMargin: 16,
                  columnSpacing: 22,
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                  columns: [
                    DataColumn(
                      label: const Text('Código'),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text('Pieza / Refacción'),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      label: const Text('Categoría'),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      numeric: true,
                      label: const Text('Stock'),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      numeric: true,
                      label: const Text('Costo Unit.'),
                      onSort: _onSort,
                    ),
                    DataColumn(
                      numeric: true,
                      label: const Text('Total Val.'),
                      onSort: _onSort,
                    ),
                    const DataColumn(
                      label: Text('Ubicación'),
                    ),
                    const DataColumn(
                      label: Text('Estado'),
                    ),
                    const DataColumn(
                      label: Text('Acción'),
                    ),
                  ],
                  rows: piezas.map((item) {
                    final int stock = item['cantidad'] as int;
                    final double costo = item['costo'] as double;
                    final double total = stock * costo;

                    Color estadoColor;
                    String estadoTexto;
                    if (stock == 0) {
                      estadoColor = Colors.red;
                      estadoTexto = 'Agotado';
                    } else if (stock < 5) {
                      estadoColor = Colors.orange;
                      estadoTexto = 'Stock Bajo';
                    } else {
                      estadoColor = Colors.green;
                      estadoTexto = 'En Stock';
                    }

                    return DataRow(
                      cells: [
                        // 1. Código
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                            child: Text(item['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                        // 2. Nombre
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                        // 3. Categoría
                        DataCell(Text(item['categoria'], style: const TextStyle(color: Colors.black54, fontSize: 13))),
                        // 4. Stock
                        DataCell(
                          Text(
                            '$stock und.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: stock == 0 ? Colors.red : (stock < 5 ? Colors.orange.shade800 : Colors.black87),
                            ),
                          ),
                        ),
                        // 5. Costo
                        DataCell(Text('\$ ${costo.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13))),
                        // 6. Total Valorado
                        DataCell(Text('\$ ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                        // 7. Ubicación
                        DataCell(Text(item['ubicacion'], style: const TextStyle(color: Colors.black54, fontSize: 12))),
                        // 8. Estado / Badge
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: estadoColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: estadoColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              estadoTexto,
                              style: TextStyle(color: estadoColor, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ),
                        // 9. Acción rápida (Ajustar Stock)
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.edit_note, size: 22, color: Colors.black87),
                            tooltip: 'Ajustar stock',
                            onPressed: () => _mostrarDialogoAjustarStock(item),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Vista alternativa en tarjetas (útil para móviles de una mano)
  Widget _buildCardsView(List<Map<String, dynamic>> piezas) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: piezas.length,
      itemBuilder: (context, index) {
        final item = piezas[index];
        final int stock = item['cantidad'] as int;
        final double costo = item['costo'] as double;
        final bool pocoStock = stock > 0 && stock < 5;
        final bool agotado = stock == 0;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: agotado
                        ? Colors.red.shade50
                        : (pocoStock ? Colors.orange.shade50 : Colors.grey.shade100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    color: agotado ? Colors.red : (pocoStock ? Colors.orange : Colors.black87),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                            child: Text(item['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                          Text(
                            item['categoria'],
                            style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(item['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('Ubicación: ${item['ubicacion']}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Unit: \$ ${costo.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          Row(
                            children: [
                              Text(
                                '$stock uds.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: agotado ? Colors.red : (pocoStock ? Colors.orange.shade800 : Colors.black),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.tune, size: 18),
                                onPressed: () => _mostrarDialogoAjustarStock(item),
                                tooltip: 'Ajustar stock',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w600)),
              Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStatusChip(String estado) {
    final bool seleccionado = _filtroEstado == estado;
    return ChoiceChip(
      label: Text(estado, style: TextStyle(fontSize: 12, fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal)),
      selected: seleccionado,
      selectedColor: Colors.black,
      labelStyle: TextStyle(color: seleccionado ? Colors.white : Colors.black87),
      backgroundColor: Colors.white,
      side: BorderSide(color: seleccionado ? Colors.black : Colors.grey.shade300),
      onSelected: (val) {
        if (val) setState(() => _filtroEstado = estado);
      },
    );
  }

  // ================================================================
  // PESTAÑA 3: VALES DE SALIDA (EXTRACCIÓN PROTEGIDA)
  // ================================================================
  Widget _buildValeSalida(BuildContext context) {
    final Map<String, dynamic> piezaElegida = _inventario.firstWhere(
      (item) => item['nombre'] == _piezaValeSeleccionada,
      orElse: () => _inventario.first,
    );
    final int stockDisponible = piezaElegida['cantidad'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.outbox_rounded, color: Colors.blueAccent, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vale de Salida de Almacén', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Control seguro de extracción y asignación a proyecto', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),

            // Selector de Pieza del Inventario
            _buildEtiqueta('Seleccionar Pieza del Inventario'),
            DropdownButtonFormField<String>(
              initialValue: _piezaValeSeleccionada,
              isExpanded: true,
              decoration: _buildInputDecoration('Pieza a extraer', icon: Icons.inventory_2_outlined),
              items: _inventario.map((item) {
                final int stock = item['cantidad'] as int;
                return DropdownMenuItem<String>(
                  value: item['nombre'] as String,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['id']} - ${item['nombre']}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '($stock disp.)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: stock == 0 ? Colors.red : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _piezaValeSeleccionada = val;
                    if (_cantidadVale > stockDisponible && stockDisponible > 0) {
                      _cantidadVale = stockDisponible;
                      _cantidadValeController.text = _cantidadVale.toString();
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 18),

            // Stepper protegido de extracción con tope de stock
            _buildEtiqueta('Cantidad a Extraer (Stock disponible: $stockDisponible)'),
            _buildStepperNumerico(
              valor: _cantidadVale,
              controller: _cantidadValeController,
              min: stockDisponible > 0 ? 1 : 0,
              max: stockDisponible > 0 ? stockDisponible : 0,
              onChanged: (nuevo) {
                setState(() {
                  _cantidadVale = nuevo;
                });
              },
            ),
            if (stockDisponible == 0) ...[
              const SizedBox(height: 6),
              const Text('⚠️ Esta pieza no tiene existencias para extraer.', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 18),

            // Proyecto Destino
            _buildEtiqueta('Proyecto / Camión Destino'),
            TextFormField(
              controller: _proyectoDestinoController,
              decoration: _buildInputDecoration('Ej. Camión 01 - Volvo 2019', icon: Icons.local_shipping_outlined),
            ),
            const SizedBox(height: 18),

            // Horas de extracción y devolución
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEtiqueta('Hora Extracción'),
                      TextField(
                        controller: _horaExtraccionController,
                        readOnly: true,
                        onTap: () => _seleccionarHora(context, _horaExtraccionController),
                        decoration: _buildInputDecoration('--:--', icon: Icons.access_time),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEtiqueta('Hora Devolución (Opc.)'),
                      TextField(
                        controller: _horaDevolucionController,
                        readOnly: true,
                        onTap: () => _seleccionarHora(context, _horaDevolucionController),
                        decoration: _buildInputDecoration('--:--', icon: Icons.access_time),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Botón Generar Vale
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: stockDisponible == 0
                    ? null
                    : () {
                        setState(() {
                          piezaElegida['cantidad'] = (piezaElegida['cantidad'] as int) - _cantidadVale;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Vale generado. Se descontaron $_cantidadVale uds. de ${piezaElegida['nombre']}.'),
                            backgroundColor: Colors.blueAccent,
                          ),
                        );
                      },
                icon: const Icon(Icons.print_outlined, color: Colors.white),
                label: const Text('Generar Vale Digital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Funciones auxiliares de estilo
  Widget _buildEtiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26, fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.black54) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
    );
  }
}