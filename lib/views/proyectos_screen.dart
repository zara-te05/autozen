import 'package:flutter/material.dart';
import '../models/proyecto_taller.dart';
import '../services/almacen_store.dart';
import '../services/proyectos_store.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/linea_etapas.dart';
import '../widgets/status_badge.dart';
import 'detalle_proyecto_screen.dart';
import 'evaluacion_screen.dart';
import '../widgets/menu_lateral.dart';

/// Lista de proyectos de un tipo (clientes o aseguradora) con pestañas de activos y archivados.
class ProyectosScreen extends StatefulWidget {
  final TipoProyecto tipo;

  const ProyectosScreen({super.key, required this.tipo});

  @override
  State<ProyectosScreen> createState() => _ProyectosScreenState();
}

class _ProyectosScreenState extends State<ProyectosScreen> with SingleTickerProviderStateMixin {
  final ProyectosStore _store = ProyectosStore.instancia;
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtro = 'Todos'; // 'Todos', 'En proceso', 'Terminados'

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

  List<ProyectoTaller> _filtrar(List<ProyectoTaller> proyectos, {required bool archivados}) {
    final q = _searchQuery.trim().toLowerCase();
    return proyectos.where((p) {
      final coincide = q.isEmpty ||
          p.nombreCamion.toLowerCase().contains(q) ||
          p.cliente.toLowerCase().contains(q) ||
          p.placa.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q) ||
          (p.aseguradora ?? '').toLowerCase().contains(q);
      if (!coincide) return false;
      if (archivados) return true;
      if (_filtro == 'En proceso') return !p.terminado;
      if (_filtro == 'Terminados') return p.terminado;
      return true;
    }).toList();
  }

  /// Todo proyecto empieza con la Evaluación de Daños; al guardarla se crea el proyecto.
  Future<void> _crearProyecto() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EvaluacionScreen(tipo: widget.tipo)),
    );
    if (mounted) _tabController.animateTo(0);
  }

  Future<void> _archivar(ProyectoTaller proyecto) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Archivar proyecto',
      message: '"${proyecto.nombreCamion}" (${proyecto.placa}) saldrá de la lista de activos y pasará a Proyectos Archivados. Podrás restaurarlo cuando quieras.',
      confirmText: 'Sí, archivar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirmar || !mounted) return;

    final error = await _store.archivar(proyecto);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      error != null
          ? SnackBar(content: Text(error), backgroundColor: AppTheme.danger)
          : SnackBar(
              content: Text('"${proyecto.nombreCamion}" se movió a Proyectos Archivados.'),
              action: SnackBarAction(label: 'Deshacer', onPressed: () => _store.restaurar(proyecto)),
            ),
    );
  }

  Future<void> _restaurar(ProyectoTaller proyecto) async {
    final error = await _store.restaurar(proyecto);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '"${proyecto.nombreCamion}" volvió a proyectos activos.'),
        backgroundColor: error == null ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: MenuLateral(seccion: widget.tipo == TipoProyecto.cliente ? Seccion.proyectosClientes : Seccion.proyectosAseguradora),
      appBar: AppBar(
        title: Text(widget.tipo.titulo),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.local_shipping_outlined, size: 20), text: 'Activos'),
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 20), text: 'Proyectos Archivados'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _crearProyecto,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Crear proyecto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ContenidoResponsivo(
        child: ListenableBuilder(
          listenable: Listenable.merge([_store, AlmacenStore.instancia]),
          builder: (context, _) => TabBarView(
            controller: _tabController,
            children: [
              _buildLista(archivados: false),
              _buildLista(archivados: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLista({required bool archivados}) {
    final todos = _store.listar(widget.tipo, archivados: archivados);
    final filtrados = _filtrar(todos, archivados: archivados);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: AppTheme.inputDecoration(
              widget.tipo == TipoProyecto.aseguradora
                  ? 'Buscar por camión, placa, cliente o aseguradora...'
                  : 'Buscar por camión, placa, cliente o ID...',
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
          if (!archivados) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildFiltroChip('Todos'),
                _buildFiltroChip('En proceso'),
                _buildFiltroChip('Terminados'),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  archivados ? 'Proyectos archivados' : 'Unidades en patio',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${filtrados.length} de ${todos.length}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtrados.isEmpty
                ? _buildVacio(archivados: archivados, hayProyectos: todos.isNotEmpty)
                : ListView.builder(
                    // Espacio inferior para que el botón flotante no tape la última tarjeta
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: filtrados.length,
                    itemBuilder: (context, index) => _buildTarjeta(filtrados[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVacio({required bool archivados, required bool hayProyectos}) {
    final String mensaje;
    if (hayProyectos) {
      mensaje = 'Ningún proyecto coincide con la búsqueda.';
    } else if (archivados) {
      mensaje = 'No hay proyectos archivados.\nUsa el bote de basura de una tarjeta para archivarla.';
    } else {
      mensaje = 'Aún no hay ${widget.tipo.singular}s.';
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(archivados ? Icons.inventory_2_outlined : Icons.local_shipping_outlined, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
            if (!archivados && !hayProyectos) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _crearProyecto,
                icon: const Icon(Icons.add, color: AppTheme.primary),
                label: const Text('Crear el primero', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String etiqueta) {
    final bool seleccionado = _filtro == etiqueta;
    return ChoiceChip(
      label: Text(etiqueta, style: TextStyle(fontSize: 12, fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal)),
      selected: seleccionado,
      showCheckmark: false,
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(color: seleccionado ? Colors.white : AppTheme.textPrimary),
      backgroundColor: Colors.white,
      side: BorderSide(color: seleccionado ? AppTheme.primary : AppTheme.border),
      onSelected: (val) {
        if (val) setState(() => _filtro = etiqueta);
      },
    );
  }

  Widget _buildTarjeta(ProyectoTaller proyecto) {
    final BadgeType badgeType = proyecto.terminado
        ? BadgeType.success
        : (proyecto.etapaActual == 0 ? BadgeType.warning : BadgeType.info);
    final String lineaCliente = proyecto.esAseguradora
        ? 'Aseguradora: ${proyecto.nombreContraparte}${proyecto.numeroSiniestro != null ? ' • ${proyecto.numeroSiniestro}' : ''}'
        : 'Cliente: ${proyecto.nombreContraparte}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: proyecto.archivado ? const Color(0xFFFAFAFA) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Color(0xFFF1F2F4), shape: BoxShape.circle),
                child: const Icon(Icons.local_shipping, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proyecto.nombreCamion,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${proyecto.id} • Placa ${proyecto.placa}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    Text(
                      lineaCliente,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              if (proyecto.archivado)
                IconButton(
                  icon: const Icon(Icons.restore, color: AppTheme.textSecondary),
                  tooltip: 'Restaurar a activos',
                  onPressed: () => _restaurar(proyecto),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.textMuted),
                  tooltip: 'Archivar proyecto',
                  onPressed: () => _archivar(proyecto),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(label: proyecto.nombreEtapaActual.toUpperCase(), type: badgeType),
              if (proyecto.esAseguradora)
                _buildDato(Icons.event_busy_outlined, 'Entrega ${formatearFecha(proyecto.fechaEntrega)}')
              else ...[
                _buildDato(Icons.schedule, '${proyecto.diasTotales} días estimados'),
                _buildDato(Icons.event_available_outlined, 'Entrega estimada ${formatearFecha(proyecto.fechaEntrega)}'),
              ],
              if (proyecto.esAseguradora && proyecto.entregaVencida)
                StatusBadge(label: 'VENCIDO ${-proyecto.diasParaEntrega}d', type: BadgeType.danger)
              else if (proyecto.entregaProxima)
                StatusBadge(
                  label: proyecto.diasParaEntrega == 0 ? 'SE ENTREGA HOY' : 'ENTREGA EN ${proyecto.diasParaEntrega}d',
                  type: BadgeType.warning,
                ),
              _buildDato(Icons.payments_outlined, '${formatearDinero(AlmacenStore.instancia.totalInvertido(proyecto.id))} invertido'),
              if (proyecto.fotos.isNotEmpty) _buildDato(Icons.photo_library_outlined, '${proyecto.fotos.length} fotos'),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          LineaEtapas(etapas: proyecto.etapas, etapaActual: proyecto.etapaActual),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetalleProyectoScreen(proyecto: proyecto)),
              ),
              icon: Icon(proyecto.archivado ? Icons.visibility_outlined : Icons.tune_outlined, size: 18, color: AppTheme.primary),
              label: Text(
                proyecto.archivado ? 'Ver detalle' : 'Gestionar unidad y etapas',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
              ),
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

  Widget _buildDato(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
