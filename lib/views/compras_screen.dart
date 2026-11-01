import 'package:flutter/material.dart';
import '../models/compras.dart';
import '../services/compras_store.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/formulario_solicitud_compra.dart';
import '../widgets/status_badge.dart';
import 'orden_compra_screen.dart';
import '../widgets/menu_lateral.dart';

/// Compras: recibe las solicitudes de los proyectos y genera las órdenes de compra.
class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> with SingleTickerProviderStateMixin {
  final ComprasStore _compras = ComprasStore.instancia;
  late final TabController _tabController;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _abrir(SolicitudCompra s) =>
      Navigator.push(context, MaterialPageRoute(builder: (context) => OrdenCompraScreen(solicitud: s)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _compras,
      builder: (context, _) {
        final pendientes = _compras.pendientes.length;
        return Scaffold(
          backgroundColor: AppTheme.background,
          drawer: const MenuLateral(seccion: Seccion.compras),
          appBar: AppBar(
            title: const Text('Compras'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              tabs: [
                Tab(text: pendientes == 0 ? 'Solicitudes' : 'Solicitudes ($pendientes)'),
                const Tab(text: 'Órdenes'),
                const Tab(text: 'Rechazadas'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => mostrarSolicitudCompra(context),
            backgroundColor: AppTheme.primary,
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: const Text('Nueva solicitud', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: ContenidoResponsivo(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLista(_compras.pendientes, vacio: 'No hay solicitudes pendientes.'),
                _buildLista(_compras.aprobadas, vacio: 'Aún no hay órdenes de compra.', resumen: true),
                _buildLista(
                  _compras.solicitudes.where((s) => s.estado == EstadoSolicitud.rechazada).toList(),
                  vacio: 'No hay solicitudes rechazadas.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLista(List<SolicitudCompra> todas, {required String vacio, bool resumen = false}) {
    final q = _busqueda.toLowerCase();
    final lista = todas
        .where((s) =>
            s.descripcion.toLowerCase().contains(q) ||
            s.proyectoNombre.toLowerCase().contains(q) ||
            s.codigo.toLowerCase().contains(q) ||
            (s.orden?.folio.toLowerCase().contains(q) ?? false) ||
            (s.orden?.proveedorNombre.toLowerCase().contains(q) ?? false))
        .toList();
    final double gasto = todas.fold(0.0, (t, s) => t + (s.orden?.total ?? 0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      children: [
        TextField(
          onChanged: (v) => setState(() => _busqueda = v),
          decoration: AppTheme.inputDecoration('Buscar por artículo, proyecto, folio o proveedor...', icon: Icons.search),
        ),
        const SizedBox(height: 16),
        if (resumen && todas.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total comprado (con IVA)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(formatearDinero(gasto), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Text('${todas.length} órdenes', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (lista.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(child: Text(vacio, style: const TextStyle(color: AppTheme.textSecondary))),
          )
        else
          for (final s in lista) _buildTarjeta(s),
      ],
    );
  }

  Widget _buildTarjeta(SolicitudCompra s) {
    final (String etiqueta, BadgeType tipo) = switch (s.estado) {
      EstadoSolicitud.pendiente => ('PENDIENTE', BadgeType.warning),
      EstadoSolicitud.aprobada => ('APROBADA', BadgeType.success),
      EstadoSolicitud.rechazada => ('RECHAZADA', BadgeType.danger),
    };
    final cantidad = s.cantidad == s.cantidad.roundToDouble() ? s.cantidad.toStringAsFixed(0) : s.cantidad.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.estado == EstadoSolicitud.pendiente ? AppTheme.warning.withValues(alpha: 0.4) : AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _abrir(s),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0xFFF1F2F4), shape: BoxShape.circle),
                      child: Icon(s.estado == EstadoSolicitud.aprobada ? Icons.receipt_long : Icons.shopping_cart_outlined, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('$cantidad ${s.unidad} • ${s.proyectoNombre}',
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(label: etiqueta, type: tipo),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _dato(Icons.tag, s.orden?.folio ?? s.codigo),
                    _dato(Icons.person_outline, s.solicitadoPor),
                    _dato(Icons.schedule, formatearFechaHora(s.fecha)),
                    if (s.orden != null) _dato(Icons.storefront_outlined, s.orden!.proveedorNombre),
                    if (s.orden != null) _dato(Icons.payments_outlined, formatearDinero(s.orden!.total)),
                  ],
                ),
                if (s.estado == EstadoSolicitud.pendiente) ...[
                  const SizedBox(height: 10),
                  const Text('Toca para completar la orden de compra →',
                      style: TextStyle(color: AppTheme.info, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
                if (s.estado == EstadoSolicitud.rechazada && s.motivoRechazo != null) ...[
                  const SizedBox(height: 8),
                  Text('Motivo: ${s.motivoRechazo}', style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dato(IconData icono, String texto) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(texto, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      );
}
