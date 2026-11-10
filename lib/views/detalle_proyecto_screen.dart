import 'package:flutter/material.dart';
import '../models/almacen_inventario.dart';
import '../models/proyecto_taller.dart';
import '../models/compras.dart';
import '../services/almacen_store.dart';
import '../services/compras_store.dart';
import '../services/fotos_service.dart';
import '../services/proyectos_store.dart';
import '../services/sesion.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/formulario_solicitud_compra.dart';
import '../widgets/documentos_proyecto.dart';
import '../widgets/galeria_fotos.dart';
import '../widgets/linea_etapas.dart';
import '../widgets/status_badge.dart';
import 'formulario_proyecto_screen.dart';

class DetalleProyectoScreen extends StatefulWidget {
  final ProyectoTaller proyecto;

  const DetalleProyectoScreen({super.key, required this.proyecto});

  @override
  State<DetalleProyectoScreen> createState() => _DetalleProyectoScreenState();
}

class _DetalleProyectoScreenState extends State<DetalleProyectoScreen> {
  final ProyectosStore _store = ProyectosStore.instancia;
  final AlmacenStore _almacen = AlmacenStore.instancia;

  final List<Map<String, dynamic>> _tareas = [
    {'titulo': 'Inspección de daños estructurales en chasis', 'completado': true},
    {'titulo': 'Desmontaje de componentes afectados', 'completado': true},
    {'titulo': 'Soldadura especializada en soporte de eje', 'completado': false},
    {'titulo': 'Instalación de kit de embrague y filtros', 'completado': false},
    {'titulo': 'Pruebas de frenos y pulido de pintura', 'completado': false},
  ];

  ProyectoTaller get _p => widget.proyecto;

  double get _progresoTareas {
    if (_tareas.isEmpty) return 0.0;
    return _tareas.where((t) => t['completado'] == true).length / _tareas.length;
  }

  Future<void> _editar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormularioProyectoScreen(tipo: _p.tipo, proyecto: _p)),
    );
  }

  Future<void> _avanzarEtapa() async {
    if (_p.terminado) return;
    final bool esUltima = _p.etapaActual == _p.etapas.length - 1;
    final String siguiente = esUltima ? 'Terminado' : _p.etapas[_p.etapaActual + 1].nombre;

    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Completar etapa',
      message: '¿Confirmas que "${_p.nombreEtapaActual}" concluyó? La unidad pasará a "$siguiente".',
      confirmText: 'Sí, avanzar',
      icon: Icons.fast_forward_rounded,
    );
    if (!confirmar || !mounted) return;

    final error = await _store.avanzarEtapa(_p);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Unidad movida a "$siguiente".'),
        backgroundColor: error == null ? AppTheme.success : AppTheme.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_store, _almacen, ComprasStore.instancia]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Detalle de unidad'),
            actions: [
              if (!_p.archivado && Sesion.editaProyectos)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar camión y etapas',
                  onPressed: _editar,
                ),
            ],
          ),
          body: ContenidoResponsivo(
            anchoMaximo: 760,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      if (_p.archivado) ...[_buildAvisoArchivado(), const SizedBox(height: 16)],
                      if (_p.esAseguradora && !_p.terminado && (_p.entregaVencida || _p.entregaProxima || _p.planExcedeEntrega)) ...[
                        _buildAvisoEntrega(),
                        const SizedBox(height: 16),
                      ],
                      _buildCabecera(),
                      const SizedBox(height: 20),
                      _buildControlEtapas(),
                      const SizedBox(height: 20),
                      _buildListaEtapas(),
                      const SizedBox(height: 20),
                      _buildMaterialAsignado(),
                      const SizedBox(height: 20),
                      _buildCompras(),
                      const SizedBox(height: 20),
                      if (_p.esAseguradora) ...[
                        DocumentosProyecto(proyecto: _p),
                        const SizedBox(height: 20),
                      ],
                      _buildEvaluacion(),
                      const SizedBox(height: 20),
                      _buildFotos(),
                      const SizedBox(height: 20),
                      _buildResponsable(),
                      const SizedBox(height: 20),
                      _buildChecklist(),
                    ],
                  ),
                ),
                // Botón fijo abajo, fuera de la lista: no tapa contenido. Solicitan compras: Admin, Proyectos y Compras
                if (!_p.archivado && Sesion.solicitaCompras)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => mostrarSolicitudCompra(context, proyecto: _p),
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                          label: const Text(
                            'Solicitar compra',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvisoArchivado() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined, color: AppTheme.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              Sesion.editaProyectos ? 'Este proyecto está archivado. Restáuralo para editarlo.' : 'Este proyecto está archivado.',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (Sesion.editaProyectos)
          TextButton(
            onPressed: () async {
              final error = await _store.restaurar(_p);
              if (error != null) _mostrarError(error);
            },
            child: const Text('Restaurar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Aviso de la fecha comprometida con la aseguradora (hay multa si no se cumple).
  Widget _buildAvisoEntrega() {
    final int dias = _p.diasParaEntrega;
    final bool urgente = _p.entregaVencida || dias == 0;
    final Color color = urgente ? AppTheme.danger : AppTheme.warning;
    final String mensaje;
    if (_p.entregaVencida) {
      mensaje = 'La fecha de entrega (${formatearFecha(_p.fechaEntrega)}) venció hace ${-dias} ${dias == -1 ? 'día' : 'días'}. La aseguradora aplica multa.';
    } else if (dias == 0) {
      mensaje = 'Hoy es la fecha de entrega a la aseguradora. Si no se entrega, hay multa.';
    } else if (_p.entregaProxima) {
      mensaje = 'Faltan $dias ${dias == 1 ? 'día' : 'días'} para la entrega a la aseguradora (${formatearFecha(_p.fechaEntrega)}).';
    } else {
      mensaje = 'El plan de etapas termina el ${formatearFecha(_p.fechaEstimadaEntrega)}, después de la entrega '
          'prometida (${formatearFecha(_p.fechaEntrega)}). Ajusta los días de las etapas.';
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(mensaje, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildCabecera() {
    final BadgeType badgeType = _p.terminado
        ? BadgeType.success
        : (_p.etapaActual == 0 ? BadgeType.warning : BadgeType.info);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(label: _p.nombreEtapaActual.toUpperCase(), type: badgeType),
              Text(
                _p.terminado ? 'Todas las etapas completas' : 'Etapa ${_p.etapaActual + 1} de ${_p.etapas.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(_p.nombreCamion, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${_p.id} • Placa ${_p.placa}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(
            _p.esAseguradora
                ? 'Aseguradora: ${_p.nombreContraparte}${_p.numeroSiniestro != null ? ' • Siniestro ${_p.numeroSiniestro}' : ''}'
                : 'Cliente: ${_p.nombreContraparte}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _buildDatoClaro(Icons.login, 'Ingreso ${formatearFecha(_p.fechaIngreso)}'),
              if (_p.esAseguradora)
                _buildDatoClaro(Icons.event_busy_outlined, 'Fecha de entrega ${formatearFecha(_p.fechaEntrega)}')
              else ...[
                _buildDatoClaro(Icons.schedule, '${_p.diasTotales} días estimados'),
                _buildDatoClaro(Icons.event_available_outlined, 'Entrega estimada ${formatearFecha(_p.fechaEntrega)}'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatoClaro(IconData icono, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTarjeta({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildControlEtapas() {
    final bool esUltima = !_p.terminado && _p.etapaActual == _p.etapas.length - 1;

    return _buildTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Avance de etapas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
              ),
              if (!_p.archivado && Sesion.editaProyectos)
                TextButton.icon(
                  onPressed: _editar,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Editar etapas'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LineaEtapas(etapas: _p.etapas, etapaActual: _p.etapaActual),
          // Avanzar etapas: solo Proyectos y el Admin
          if (Sesion.editaProyectos || _p.terminado) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: !_p.terminado && !_p.archivado && Sesion.editaProyectos ? _avanzarEtapa : null,
              icon: Icon(_p.terminado ? Icons.check_circle : Icons.arrow_circle_right_outlined, color: Colors.white, size: 18),
              label: Text(
                _p.terminado
                    ? 'Proyecto terminado'
                    : esUltima
                        ? 'Completar "${_p.nombreEtapaActual}" y terminar'
                        : 'Completar "${_p.nombreEtapaActual}"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _p.terminado ? AppTheme.success : AppTheme.primary,
                disabledBackgroundColor: _p.terminado ? AppTheme.success : Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildListaEtapas() {
    return _buildTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plan de etapas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          for (int i = 0; i < _p.etapas.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    i < _p.etapaActual
                        ? Icons.check_circle
                        : i == _p.etapaActual
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                    size: 18,
                    color: i <= _p.etapaActual ? AppTheme.primary : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${i + 1}. ${_p.etapas[i].nombre}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: i == _p.etapaActual ? FontWeight.bold : FontWeight.normal,
                        color: i < _p.etapaActual ? AppTheme.textMuted : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_p.etapas[i].diasEstimados} ${_p.etapas[i].diasEstimados == 1 ? 'día' : 'días'}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _encabezado(String titulo, {String? derecha}) {
    return Row(
      children: [
        Expanded(child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
        if (derecha != null)
          Text(derecha, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildMaterialAsignado() {
    final vales = _almacen.valesMaterialDe(_p.id);
    final herramientas = _almacen.herramientasDe(_p.id);
    final pendientes = herramientas.where((h) => !h.devuelto).toList();
    final double invertido = _almacen.totalInvertido(_p.id);

    // Cantidad total por material (puede venir en varios vales)
    final Map<String, ({String nombre, UnidadMedida unidad, double cantidad, double total})> resumen = {};
    for (final v in vales) {
      final previo = resumen[v.articuloId];
      resumen[v.articuloId] = (
        nombre: v.articuloNombre,
        unidad: v.unidad,
        cantidad: (previo?.cantidad ?? 0) + v.cantidad,
        total: (previo?.total ?? 0) + v.total,
      );
    }

    return _buildTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezado('Material asignado'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _indicador('Dinero invertido', formatearDinero(invertido), Icons.payments_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _indicador('Herramientas por regresar', '${pendientes.length}', Icons.handyman_outlined)),
            ],
          ),
          const SizedBox(height: 12),
          if (resumen.isEmpty)
            const Text('Aún no se le ha entregado material desde almacén.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
          else
            for (final m in resumen.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(m.nombre, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                    const SizedBox(width: 8),
                    Text(m.unidad.formatear(m.cantidad), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      child: Text(formatearDinero(m.total),
                          textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
          if (pendientes.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('Herramientas prestadas (deben volver)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 6),
            for (final h in pendientes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.handyman_outlined, size: 16, color: AppTheme.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${h.unidad.formatear(h.cantidad)} • ${h.articuloNombre}',
                          overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    ),
                    Text(h.entregadoA, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompras() {
    final solicitudes = ComprasStore.instancia.solicitudesDe(_p.id);
    return _buildTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezado('Compras del proyecto', derecha: '${solicitudes.length}'),
          const SizedBox(height: 8),
          if (solicitudes.isEmpty)
            const Text('No se ha solicitado ninguna compra.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12))
          else
            for (final s in solicitudes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      switch (s.estado) {
                        EstadoSolicitud.pendiente => Icons.hourglass_top,
                        EstadoSolicitud.aprobada => Icons.verified_outlined,
                        EstadoSolicitud.rechazada => Icons.block,
                      },
                      size: 18,
                      color: switch (s.estado) {
                        EstadoSolicitud.pendiente => AppTheme.warning,
                        EstadoSolicitud.aprobada => AppTheme.success,
                        EstadoSolicitud.rechazada => AppTheme.danger,
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.descripcion} • ${s.estado.nombre}${s.orden != null ? ' (${s.orden!.folio})' : ''}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    if (s.orden != null)
                      Text(formatearDinero(s.orden!.total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _indicador(String titulo, String valor, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Icon(icono, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluacion() {
    return _buildTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezado(
            'Evaluación de daños',
            derecha: _p.fechaEvaluacion == null ? null : formatearFecha(_p.fechaEvaluacion!),
          ),
          const SizedBox(height: 10),
          Text(
            _p.descripcionDanos.isEmpty ? 'Sin diagnóstico registrado.' : _p.descripcionDanos,
            style: TextStyle(fontSize: 13, color: _p.descripcionDanos.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary),
          ),
          if (_p.refaccionesCotizadas.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Refacciones cotizadas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 4),
            for (final r in _p.refaccionesCotizadas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text('• ${r.cantidad} × ${r.nombre}', style: const TextStyle(fontSize: 13)),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _quitarFoto(String ruta) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar foto',
      message: '¿Eliminar esta foto del proyecto?',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirmar) return;
    final error = await _store.quitarFoto(_p, ruta);
    if (error != null) _mostrarError(error);
  }

  Future<void> _agregarFoto(String ruta) async {
    final error = await _store.agregarFoto(_p, ruta);
    if (error != null) {
      await FotosService.borrar(ruta);
      _mostrarError(error);
    }
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje), backgroundColor: AppTheme.danger));
  }

  Widget _buildFotos() {
    return _buildTarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezado('Fotos', derecha: '${_p.fotos.length}'),
          const SizedBox(height: 12),
          GaleriaFotos(
            fotos: _p.fotos,
            editable: !_p.archivado && Sesion.creaProyectos,
            onAgregada: _agregarFoto,
            onQuitada: _quitarFoto,
          ),
        ],
      ),
    );
  }

  Widget _buildResponsable() {
    return Container(
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
            decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
            child: const Icon(Icons.engineering_outlined, color: AppTheme.info),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _p.responsable.isEmpty ? 'Sin responsable asignado' : _p.responsable,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Text('Especialista técnico responsable', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklist() {
    final double progreso = _progresoTareas;
    final int pct = (progreso * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Text('Checklist de tareas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            Text('$pct% completado', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progreso,
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
          child: Column(
            children: [
              for (int i = 0; i < _tareas.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                CheckboxListTile(
                  value: _tareas[i]['completado'] as bool,
                  activeColor: AppTheme.primary,
                  onChanged: _p.archivado || !Sesion.editaProyectos ? null : (val) => setState(() => _tareas[i]['completado'] = val ?? false),
                  title: Text(
                    _tareas[i]['titulo'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _tareas[i]['completado'] == true ? FontWeight.normal : FontWeight.w600,
                      color: _tareas[i]['completado'] == true ? AppTheme.textMuted : AppTheme.textPrimary,
                      decoration: _tareas[i]['completado'] == true ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
