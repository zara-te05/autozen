import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/almacen_inventario.dart';
import '../models/compras.dart';
import '../services/almacen_store.dart';
import '../services/compras_store.dart';
import '../services/proveedores_store.dart';
import '../services/sesion.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import '../widgets/aviso_solo_lectura.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/hoja_orden_compra.dart';

/// Compras abre una solicitud, completa la orden de compra y la aprueba o la rechaza.
/// Si ya fue atendida, muestra la orden como la hoja impresa.
class OrdenCompraScreen extends StatefulWidget {
  final SolicitudCompra solicitud;

  const OrdenCompraScreen({super.key, required this.solicitud});

  @override
  State<OrdenCompraScreen> createState() => _OrdenCompraScreenState();
}

class _PartidaEditable {
  final Key key = UniqueKey();
  final TextEditingController articulo;
  final TextEditingController nombre;
  final TextEditingController unidades;
  final TextEditingController precio;
  final TextEditingController descuento;
  String unidad;

  _PartidaEditable(PartidaOrden p)
      : articulo = TextEditingController(text: p.articulo),
        nombre = TextEditingController(text: p.nombre),
        unidades = TextEditingController(text: _texto(p.unidades)),
        precio = TextEditingController(text: p.precio == 0 ? '' : p.precio.toStringAsFixed(2)),
        descuento = TextEditingController(text: p.descuento == 0 ? '' : p.descuento.toStringAsFixed(2)),
        unidad = unidadesOrden.contains(p.unidad) ? p.unidad : unidadesOrden.first;

  static String _texto(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  PartidaOrden get valor => PartidaOrden(
        articulo: articulo.text.trim(),
        nombre: nombre.text.trim(),
        unidad: unidad,
        unidades: double.tryParse(unidades.text) ?? 0,
        precio: double.tryParse(precio.text) ?? 0,
        descuento: double.tryParse(descuento.text) ?? 0,
      );

  void dispose() {
    for (final c in [articulo, nombre, unidades, precio, descuento]) {
      c.dispose();
    }
  }
}

class _OrdenCompraScreenState extends State<OrdenCompraScreen> {
  final _formKey = GlobalKey<FormState>();
  final ComprasStore _compras = ComprasStore.instancia;
  final TextEditingController _consignatario = TextEditingController();
  final TextEditingController _via = TextEditingController();
  final TextEditingController _observaciones = TextEditingController();
  final List<_PartidaEditable> _partidas = [];
  late String _folio;
  DateTime _fecha = DateTime.now();
  DateTime _entrega = DateTime.now().add(const Duration(days: 3));
  String? _proveedorId;
  String _condiciones = condicionesPago.first;
  bool _conIva = true;
  bool _guardando = false;

  SolicitudCompra get _s => widget.solicitud;
  /// Solo Compras y el Admin completan, aprueban o rechazan; los demás ven la solicitud en modo consulta.
  bool get _editable => _s.estado == EstadoSolicitud.pendiente && Sesion.editaCompras;

  @override
  void initState() {
    super.initState();
    _folio = _compras.siguienteFolio();
    // La solicitud se convierte en la primera partida de la orden
    _partidas.add(_PartidaEditable(PartidaOrden(nombre: _s.descripcion, unidad: _s.unidad, unidades: _s.cantidad)));
    _observaciones.text = _s.notas;
  }

  @override
  void dispose() {
    _consignatario.dispose();
    _via.dispose();
    _observaciones.dispose();
    for (final p in _partidas) {
      p.dispose();
    }
    super.dispose();
  }

  OrdenCompraDoc _armarOrden() {
    final proveedores = ProveedoresStore.instancia.proveedores;
    final proveedor = proveedores.where((p) => p.id == _proveedorId).firstOrNull;
    return OrdenCompraDoc(
      folio: _folio,
      fecha: _fecha,
      proveedorId: proveedor?.serverId,
      proveedorNombre: proveedor?.nombre ?? '',
      proveedorDireccion: proveedor?.direccion ?? '',
      consignatario: _consignatario.text.trim(),
      entrega: _entrega,
      condiciones: _condiciones,
      viaEmbarque: _via.text.trim(),
      partidas: _partidas.map((p) => p.valor).toList(),
      tasaIva: _conIva ? 0.16 : 0,
      observaciones: _observaciones.text.trim(),
    );
  }

  Future<void> _elegirFecha({required bool entrega}) async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: entrega ? _entrega : _fecha,
      firstDate: DateTime(2025),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (seleccion == null) return;
    setState(() {
      if (entrega) {
        _entrega = seleccion;
      } else {
        _fecha = seleccion;
      }
    });
  }

  void _quitarPartida(int i) {
    final quitada = _partidas[i];
    setState(() => _partidas.removeAt(i));
    WidgetsBinding.instance.addPostFrameCallback((_) => quitada.dispose());
  }

  Future<void> _agregarDelCatalogo() async {
    final articulos = AlmacenStore.instancia.articulos.toList()..sort((a, b) => a.nombre.compareTo(b.nombre));
    final elegido = await showDialog<Articulo>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Artículo del catálogo'),
        children: [
          SizedBox(
            width: 420,
            height: 360,
            child: ListView(
              children: [
                for (final a in articulos)
                  ListTile(
                    dense: true,
                    title: Text(a.nombre),
                    subtitle: Text('${a.id} • ${formatearDinero(a.costoUnitario)} / ${a.unidad.abreviatura}'),
                    onTap: () => Navigator.pop(ctx, a),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (elegido == null) return;
    setState(() => _partidas.add(_PartidaEditable(PartidaOrden(
          articulo: elegido.id,
          nombre: elegido.nombre,
          unidad: _unidadDe(elegido.unidad),
          unidades: 1,
          precio: elegido.costoUnitario,
        ))));
  }

  static String _unidadDe(UnidadMedida u) => switch (u) {
        UnidadMedida.pieza => 'Pieza',
        UnidadMedida.kilogramo => 'Kilogramo',
        UnidadMedida.litro => 'Litro',
        UnidadMedida.metro => 'Metro',
        UnidadMedida.juego => 'Juego',
        UnidadMedida.caja => 'Caja',
      };

  void _vistaPrevia(OrdenCompraDoc orden) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFFE4E4E7),
          appBar: AppBar(title: Text('Orden ${orden.folio}')),
          body: InteractiveViewer(
            maxScale: 4,
            child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: HojaOrdenCompra(orden: orden)),
          ),
        ),
      ),
    );
  }

  Future<void> _aprobar() async {
    if (_guardando || !_formKey.currentState!.validate()) return;
    final orden = _armarOrden();
    setState(() => _guardando = true);
    final error = await _compras.aprobar(_s, orden);
    if (!mounted) return;
    setState(() => _guardando = false);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.danger));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Orden ${_s.orden?.folio ?? orden.folio} generada.'), backgroundColor: AppTheme.success),
    );
  }

  Future<void> _rechazar() async {
    final motivo = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar solicitud'),
        content: TextField(
          controller: motivo,
          autofocus: true,
          maxLines: 3,
          decoration: AppTheme.inputDecoration('Motivo (se le mostrará a quien la pidió)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    final texto = motivo.text;
    motivo.dispose();
    if (confirmado != true) return;
    final error = await _compras.rechazar(_s, texto);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Solicitud rechazada.'), backgroundColor: error == null ? AppTheme.success : AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_compras, ProveedoresStore.instancia]),
      builder: (context, _) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(_editable ? 'Completar orden de compra' : (_s.orden?.folio ?? _s.codigo)),
          actions: [
            if (!_editable && _s.orden != null)
              IconButton(icon: const Icon(Icons.fullscreen), tooltip: 'Ver hoja completa', onPressed: () => _vistaPrevia(_s.orden!)),
          ],
        ),
        body: ContenidoResponsivo(
          anchoMaximo: 900,
          child: _editable ? _buildFormulario() : _buildLectura(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ Solicitud ya atendida

  Widget _buildLectura() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSolicitud(),
        const SizedBox(height: 16),
        if (_s.estado == EstadoSolicitud.pendiente)
          const AvisoSoloLectura('Solicitud pendiente: el área de Compras la revisará para aprobarla o rechazarla.')
        else if (_s.estado == EstadoSolicitud.rechazada)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: Text('Solicitud rechazada: ${_s.motivoRechazo ?? 'sin motivo'}',
                style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600)),
          )
        else if (_s.orden != null)
          HojaOrdenCompra(orden: _s.orden!),
      ],
    );
  }

  // ------------------------------------------------------------------ Formulario

  Widget _buildFormulario() {
    final orden = _armarOrden();
    final proveedores = ProveedoresStore.instancia.proveedores;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _buildSolicitud(),
          const SizedBox(height: 16),
          _seccion(
            titulo: 'Datos de la orden',
            derecha: _folio,
            children: [
              Row(
                children: [
                  Expanded(child: _campoFecha('Fecha', _fecha, () => _elegirFecha(entrega: false))),
                  const SizedBox(width: 12),
                  Expanded(child: _campoFecha('Entrega', _entrega, () => _elegirFecha(entrega: true))),
                ],
              ),
              _etiqueta('Proveedor *'),
              DropdownButtonFormField<String>(
                initialValue: _proveedorId,
                isExpanded: true,
                decoration: AppTheme.inputDecoration(proveedores.isEmpty ? 'Registra proveedores primero' : 'Selecciona', icon: Icons.storefront_outlined),
                items: [for (final p in proveedores) DropdownMenuItem(value: p.id, child: Text(p.nombre, overflow: TextOverflow.ellipsis))],
                validator: (v) => v == null ? 'Elige el proveedor' : null,
                onChanged: (v) => setState(() {
                  _proveedorId = v;
                  final p = proveedores.where((x) => x.id == v).firstOrNull;
                  if (p != null) _entrega = _fecha.add(Duration(days: p.tiempoEntregaDias));
                }),
              ),
              if (orden.proveedorDireccion.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(orden.proveedorDireccion, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
              _etiqueta('Consignatario'),
              TextFormField(controller: _consignatario, decoration: AppTheme.inputDecoration('Opcional: quién recibe', icon: Icons.local_post_office_outlined)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta('Condiciones'),
                        DropdownButtonFormField<String>(
                          initialValue: _condiciones,
                          isExpanded: true,
                          decoration: AppTheme.inputDecoration(''),
                          items: [for (final c in condicionesPago) DropdownMenuItem(value: c, child: Text(c))],
                          onChanged: (v) => setState(() => _condiciones = v ?? _condiciones),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _etiqueta('Vía de embarque'),
                        TextFormField(controller: _via, decoration: AppTheme.inputDecoration('Ej. Recoger en sucursal')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _seccion(
            titulo: 'Artículos',
            derecha: '${_partidas.length}',
            children: [
              for (int i = 0; i < _partidas.length; i++) _buildPartida(i),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _partidas.add(_PartidaEditable(PartidaOrden(nombre: '')))),
                    icon: const Icon(Icons.add, size: 18, color: AppTheme.primary),
                    label: const Text('Agregar artículo', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _agregarDelCatalogo,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.primary),
                    label: const Text('Del catálogo de almacén', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _seccion(
            titulo: 'Totales',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _conIva,
                activeThumbColor: AppTheme.primary,
                title: const Text('Agregar IVA (16 %)', style: TextStyle(fontSize: 14)),
                onChanged: (v) => setState(() => _conIva = v),
              ),
              _filaTotal('Subtotal', orden.subtotal),
              _filaTotal('IVA', orden.iva),
              const Divider(),
              _filaTotal('Total', orden.total, fuerte: true),
              const SizedBox(height: 6),
              Text('(${orden.totalConLetra})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
              _etiqueta('Observaciones'),
              TextFormField(controller: _observaciones, maxLines: 2, decoration: AppTheme.inputDecoration('Opcional')),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _vistaPrevia(orden),
              icon: const Icon(Icons.description_outlined, color: AppTheme.primary),
              label: const Text('Vista previa de la hoja', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _guardando ? null : _rechazar,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.danger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Rechazar', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _aprobar,
                    icon: const Icon(Icons.verified_outlined, color: Colors.white),
                    label: const Text('Aprobar y generar orden', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitud() {
    final cantidad = _s.cantidad == _s.cantidad.roundToDouble() ? _s.cantidad.toStringAsFixed(0) : _s.cantidad.toString();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_s.codigo} • ${_s.estado.nombre.toUpperCase()}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_s.descripcion, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text('$cantidad ${_s.unidad}', style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 8),
          Text('Proyecto: ${_s.proyectoNombre}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('Solicitó: ${_s.solicitadoPor} • ${formatearFechaHora(_s.fecha)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (_s.notas.isNotEmpty) Text('Notas: ${_s.notas}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPartida(int i) {
    final p = _partidas[i];
    final importe = p.valor.importe;
    return Container(
      key: p.key,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 12),
      decoration: BoxDecoration(color: AppTheme.inputFill, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text('Artículo ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary))),
              Text(formatearDinero(importe), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                tooltip: 'Quitar',
                onPressed: _partidas.length > 1 ? () => _quitarPartida(i) : null,
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: TextFormField(controller: p.articulo, decoration: AppTheme.inputDecoration('Clave')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: p.nombre,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Nombre' : null,
                  decoration: AppTheme.inputDecoration('Nombre del artículo'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, c) {
            // En pantallas angostas los cuatro campos bajan a dos renglones
            final ancho = c.maxWidth >= 520 ? (c.maxWidth - 24) / 4 : (c.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SizedBox(
                  width: ancho,
                  child: DropdownButtonFormField<String>(
                    initialValue: p.unidad,
                    isExpanded: true,
                    decoration: AppTheme.inputDecoration('U.med.'),
                    items: [for (final u in unidadesOrden) DropdownMenuItem(value: u, child: Text(u, overflow: TextOverflow.ellipsis))],
                    onChanged: (v) => setState(() => p.unidad = v ?? p.unidad),
                  ),
                ),
                SizedBox(width: ancho, child: _numero(p.unidades, 'Unidades', requerido: true, decimales: 3)),
                SizedBox(width: ancho, child: _numero(p.precio, 'Precio', requerido: true)),
                SizedBox(width: ancho, child: _numero(p.descuento, 'Descto. \$')),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _numero(TextEditingController c, String hint, {bool requerido = false, int decimales = 2}) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp('^\\d*\\.?\\d{0,$decimales}'))],
      onChanged: (_) => setState(() {}),
      validator: requerido ? (v) => (double.tryParse(v ?? '') ?? -1) < 0 || (v ?? '').isEmpty ? 'Requerido' : null : null,
      decoration: AppTheme.inputDecoration(hint),
    );
  }

  Widget _campoFecha(String etiqueta, DateTime fecha, VoidCallback onTap) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _etiqueta(etiqueta),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: AppTheme.inputDecoration('', icon: Icons.calendar_today),
              child: Text(formatearFecha(fecha)),
            ),
          ),
        ],
      );

  Widget _filaTotal(String texto, double valor, {bool fuerte = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(texto, style: TextStyle(fontWeight: fuerte ? FontWeight.bold : FontWeight.normal, fontSize: fuerte ? 16 : 14))),
            Text(formatearDinero(valor), style: TextStyle(fontWeight: fuerte ? FontWeight.w900 : FontWeight.w600, fontSize: fuerte ? 16 : 14)),
          ],
        ),
      );

  Widget _etiqueta(String texto) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _seccion({required String titulo, String? derecha, required List<Widget> children}) => Container(
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
                if (derecha != null) Text(derecha, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      );
}
