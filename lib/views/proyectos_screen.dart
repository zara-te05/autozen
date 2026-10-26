import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/status_badge.dart';
import 'detalle_proyecto_screen.dart';

class ProyectosScreen extends StatefulWidget {
  const ProyectosScreen({super.key});

  @override
  State<ProyectosScreen> createState() => _ProyectosScreenState();
}

class _ProyectosScreenState extends State<ProyectosScreen> {
  // Datos controlados de proyectos en patio
  final List<Map<String, dynamic>> _proyectos = [
    {
      'id': 'PRJ-001',
      'nombre': 'Camión 01 - Volvo 2019',
      'cliente': 'Transportes del Norte',
      'etapa_actual': 1, // 0: Evaluación, 1: Refacciones, 2: Reparación, 3: Terminado
      'fecha_ingreso': '12/Oct/2026',
      'responsable': 'Sergio Urey Morales',
    },
    {
      'id': 'PRJ-002',
      'nombre': 'Camión 02 - Kenworth T680',
      'cliente': 'Logística Express',
      'etapa_actual': 2,
      'fecha_ingreso': '08/Oct/2026',
      'responsable': 'Carlos Martínez',
    },
    {
      'id': 'PRJ-003',
      'nombre': 'Camión 03 - Freightliner Cascadia',
      'cliente': 'Grupo Modelo',
      'etapa_actual': 0,
      'fecha_ingreso': '14/Oct/2026',
      'responsable': 'Roberto Gómez',
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroEtapa = 'Todos'; // 'Todos', 'Evaluación', 'Refacciones', 'Reparación', 'Terminado'

  static const List<String> etapasNombre = [
    'Evaluación',
    'Refacciones',
    'Reparación',
    'Terminado',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _proyectosFiltrados {
    return _proyectos.where((p) {
      final q = _searchQuery.toLowerCase();
      final matchText = p['nombre'].toString().toLowerCase().contains(q) ||
          p['cliente'].toString().toLowerCase().contains(q) ||
          p['id'].toString().toLowerCase().contains(q);

      if (!matchText) return false;

      final int etapa = p['etapa_actual'] as int;
      if (_filtroEtapa == 'Evaluación') return etapa == 0;
      if (_filtroEtapa == 'Refacciones') return etapa == 1;
      if (_filtroEtapa == 'Reparación') return etapa == 2;
      if (_filtroEtapa == 'Terminado') return etapa == 3;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _proyectosFiltrados;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Panel de Proyectos'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buscador controlado
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: AppTheme.inputDecoration(
                'Buscar por camión, cliente o ID...',
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
            const SizedBox(height: 12),

            // Filtros rápidos por etapa (evita entradas inválidas)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFiltroChip('Todos'),
                  const SizedBox(width: 6),
                  _buildFiltroChip('Evaluación'),
                  const SizedBox(width: 6),
                  _buildFiltroChip('Refacciones'),
                  const SizedBox(width: 6),
                  _buildFiltroChip('Reparación'),
                  const SizedBox(width: 6),
                  _buildFiltroChip('Terminado'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Unidades en Patio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text('${filtrados.length} registradas', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            Expanded(
              child: filtrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.directions_bus_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No se encontraron camiones en esta etapa.', style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtrados.length,
                      itemBuilder: (context, index) {
                        final proyecto = filtrados[index];
                        return _buildTarjetaProyecto(proyecto);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String etapa) {
    final bool seleccionado = _filtroEtapa == etapa;
    return ChoiceChip(
      label: Text(etapa, style: TextStyle(fontSize: 12, fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal)),
      selected: seleccionado,
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(color: seleccionado ? Colors.white : AppTheme.textPrimary),
      backgroundColor: Colors.white,
      side: BorderSide(color: seleccionado ? AppTheme.primary : AppTheme.border),
      onSelected: (val) {
        if (val) setState(() => _filtroEtapa = etapa);
      },
    );
  }

  Widget _buildTarjetaProyecto(Map<String, dynamic> proyecto) {
    final int etapa = proyecto['etapa_actual'] as int;

    BadgeType badgeType;
    if (etapa == 0) {
      badgeType = BadgeType.warning;
    } else if (etapa == 1) {
      badgeType = BadgeType.info;
    } else if (etapa == 2) {
      badgeType = BadgeType.warning;
    } else {
      badgeType = BadgeType.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF1F2F4), shape: BoxShape.circle),
                    child: const Icon(Icons.local_shipping, color: AppTheme.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(proyecto['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${proyecto['id']} • ${proyecto['cliente']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              StatusBadge(
                label: etapasNombre[etapa].toUpperCase(),
                type: badgeType,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),

          // Línea de tiempo defensiva (pasos secuenciales)
          Row(
            children: [
              _buildPasoTimeline('Evaluación', etapa >= 0, etapa == 0),
              _buildLineaConectora(etapa >= 1),
              _buildPasoTimeline('Refacciones', etapa >= 1, etapa == 1),
              _buildLineaConectora(etapa >= 2),
              _buildPasoTimeline('Reparación', etapa >= 2, etapa == 2),
              _buildLineaConectora(etapa >= 3),
              _buildPasoTimeline('Listo', etapa >= 3, etapa == 3),
            ],
          ),
          const SizedBox(height: 16),

          // Botón de acceso
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleProyectoScreen(
                      nombreProyecto: proyecto['nombre'],
                      cliente: proyecto['cliente'],
                      etapaActual: proyecto['etapa_actual'],
                      responsable: proyecto['responsable'],
                      onEtapaUpdated: (nuevaEtapa) {
                        setState(() {
                          proyecto['etapa_actual'] = nuevaEtapa;
                        });
                      },
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.tune_outlined, size: 18, color: AppTheme.primary),
              label: const Text('Gestionar Unidad y Tareas', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoTimeline(String titulo, bool completado, bool actual) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: actual ? 12 : 9,
            backgroundColor: completado ? AppTheme.primary : const Color(0xFFE4E4E7),
            child: completado
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 10,
              fontWeight: actual ? FontWeight.bold : FontWeight.normal,
              color: actual ? AppTheme.primary : AppTheme.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLineaConectora(bool activa) {
    return Expanded(
      child: Container(
        height: 2,
        color: activa ? AppTheme.primary : const Color(0xFFE4E4E7),
      ),
    );
  }
}