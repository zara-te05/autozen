import 'package:flutter/material.dart';
import '../models/almacen_inventario.dart';
import '../models/proyecto_taller.dart';
import '../models/resguardo.dart';
import '../services/almacen_store.dart';
import '../services/proyectos_store.dart';
import '../services/sesion.dart';
import '../utils/app_theme.dart';
import '../utils/formato_fecha.dart';
import '../widgets/aviso_solo_lectura.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/animaciones.dart';
import '../widgets/contenido_responsivo.dart';
import '../widgets/dialogo_categorias.dart';
import '../widgets/formulario_articulo.dart';
import '../widgets/formulario_resguardo.dart';
import '../widgets/status_badge.dart';
import '../widgets/menu_lateral.dart';

class AlmacenScreen extends StatefulWidget {
  const AlmacenScreen({super.key});

  @override
  State<AlmacenScreen> createState() => _AlmacenScreenState();
}

class _AlmacenScreenState extends State<AlmacenScreen> with SingleTickerProviderStateMixin {
  final AlmacenStore _almacen = AlmacenStore.instancia;
  final ProyectosStore _proyectos = ProyectosStore.instancia;
  late final TabController _tabController;

  // Desglose
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtro = 'Todos'; // Todos, Materiales, Herramientas, Bajo stock, Agotados
  bool _vistaTabla = true;
  int _ordenColumna = 1;
  bool _ordenAscendente = true;

  // Vale de material
  final _formMaterial = GlobalKey<FormState>();
  String? _proyectoMaterial;
  String? _articuloMaterial;
  final TextEditingController _cantidadMaterial = TextEditingController();
  final TextEditingController _entregadoMaterial = TextEditingController();

  // Vale de herramienta
  final _formHerramienta = GlobalKey<FormState>();
  String? _proyectoHerramienta;
  String? _articuloHerramienta;
  final TextEditingController _cantidadHerramienta = TextEditingController(text: '1');
  final TextEditingController _entregadoHerramienta = TextEditingController();

  @override
  void initState() {
    super.initState();
    // La pestaña 'Alta de Piezas' solo existe para quien puede editar el almacén
    _tabController = TabController(length: Sesion.editaAlmacen ? 5 : 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final c in [_searchController, _cantidadMaterial, _entregadoMaterial, _cantidadHerramienta, _entregadoHerramienta]) {
      c.dispose();
    }
    super.dispose();
  }

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: error ? AppTheme.danger : AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      drawer: const MenuLateral(seccion: Seccion.almacen),
      appBar: AppBar(
        title: const Text('Gestión de Almacén'),
        actions: [
          if (Sesion.editaAlmacen)
            IconButton(
              icon: const Icon(Icons.category_outlined),
              tooltip: 'Administrar categorías',
              onPressed: () => mostrarDialogoCategorias(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: [
            if (Sesion.editaAlmacen) const Tab(text: 'Alta de Piezas'),
            const Tab(text: 'Desglose de inventario'),
            const Tab(text: 'Vales de Material'),
            const Tab(text: 'Herramientas (deben volver)'),
            const Tab(text: 'Placas y resguardos'),
          ],
        ),
      ),
      body: ContenidoResponsivo(
        anchoMaximo: 1200,
        child: ListenableBuilder(
          listenable: Listenable.merge([_almacen, _proyectos]),
          builder: (context, _) => TabBarView(
            controller: _tabController,
            children: [
              if (Sesion.editaAlmacen)
                ContenidoResponsivo(anchoMaximo: 760, child: FormularioArticulo(onGuardado: () => _tabController.animateTo(1))),
              _buildDesglose(),
              _buildValesMaterial(),
              _buildHerramientas(),
              _buildResguardos(),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // DESGLOSE DE INVENTARIO
  // =====================================================================

  List<Articulo> get _articulosFiltrados {
    final q = _searchQuery.trim().toLowerCase();
    final lista = _almacen.articulos.where((a) {
      final coincide = q.isEmpty || a.nombre.toLowerCase().contains(q) || a.id.toLowerCase().contains(q) || a.categoria.toLowerCase().contains(q);
      if (!coincide) return false;
      return switch (_filtro) {
        'Materiales' => a.tipo == TipoArticulo.material,
        'Herramientas' => a.tipo == TipoArticulo.herramienta,
        'Bajo stock' => a.bajoStock,
        'Agotados' => a.agotado,
        _ => true,
      };
    }).toList();

    int comparar(Articulo a, Articulo b) => switch (_ordenColumna) {
          0 => a.id.compareTo(b.id),
          1 => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
          4 => a.existencia.compareTo(b.existencia),
          6 => a.valorEnAlmacen.compareTo(b.valorEnAlmacen),
          _ => 0,
        };
    lista.sort((a, b) => _ordenAscendente ? comparar(a, b) : comparar(b, a));
    return lista;
  }

  Future<void> _editarArticulo(Articulo articulo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(title: const Text('Editar artículo')),
          body: ContenidoResponsivo(
            anchoMaximo: 760,
            child: FormularioArticulo(articulo: articulo, onGuardado: () => Navigator.pop(ctx)),
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarArticulo(Articulo articulo) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar artículo',
      message: '¿Eliminar "${articulo.nombre}" del catálogo? Los vales ya registrados se conservan.',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirmar || !mounted) return;
    final error = await _almacen.eliminarArticulo(articulo);
    if (!mounted) return;
    _mensaje(error ?? '"${articulo.nombre}" eliminado.', error: error != null);
  }

  Widget _buildDesglose() {
    final todos = _almacen.articulos;
    final filtrados = _articulosFiltrados;
    final double valorTotal = todos.fold(0.0, (s, a) => s + a.valorEnAlmacen);
    final int prestadas = _almacen.valesHerramienta.where((v) => !v.devuelto).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _kpi('Artículos', '${todos.length}', Icons.inventory_2_outlined, Colors.black87),
                _kpi('Valor en almacén', formatearDinero(valorTotal), Icons.payments_outlined, Colors.blueGrey),
                _kpi('Bajo stock (<5)', '${todos.where((a) => a.bajoStock).length}', Icons.warning_amber_rounded, Colors.orange),
                _kpi('Agotados', '${todos.where((a) => a.agotado).length}', Icons.highlight_off, Colors.redAccent),
                _kpi('Herramientas prestadas', '$prestadas', Icons.handyman_outlined, AppTheme.info),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: AppTheme.inputDecoration('Buscar por código, nombre o categoría...', icon: Icons.search),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: Icon(_vistaTabla ? Icons.grid_view : Icons.table_chart_outlined),
                    tooltip: _vistaTabla ? 'Ver como tarjetas' : 'Ver como tabla',
                    onPressed: () => setState(() => _vistaTabla = !_vistaTabla),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final f in ['Todos', 'Materiales', 'Herramientas', 'Bajo stock', 'Agotados']) _chipFiltro(f)],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtrados.isEmpty
              ? const Center(child: Text('No hay artículos con ese criterio.', style: TextStyle(color: AppTheme.textSecondary)))
              : (_vistaTabla ? _buildTabla(filtrados) : _buildTarjetasArticulos(filtrados)),
        ),
      ],
    );
  }

  Widget _kpi(String titulo, String valor, IconData icono, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.cardShadow),
      child: Row(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
              Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chipFiltro(String etiqueta) {
    final sel = _filtro == etiqueta;
    return ChoiceChip(
      label: Text(etiqueta, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      selected: sel,
      showCheckmark: false,
      selectedColor: AppTheme.primary,
      labelStyle: TextStyle(color: sel ? Colors.white : AppTheme.textPrimary),
      backgroundColor: Colors.white,
      side: BorderSide(color: sel ? AppTheme.primary : AppTheme.border),
      onSelected: (v) {
        if (v) setState(() => _filtro = etiqueta);
      },
    );
  }

  ({String texto, BadgeType tipo}) _estado(Articulo a) {
    if (a.agotado) return (texto: 'AGOTADO', tipo: BadgeType.danger);
    if (a.bajoStock) return (texto: 'BAJO STOCK', tipo: BadgeType.warning);
    return (texto: 'EN STOCK', tipo: BadgeType.success);
  }

  void _ordenar(int columna, bool ascendente) => setState(() {
        _ordenColumna = columna;
        _ordenAscendente = ascendente;
      });

  Widget _buildTabla(List<Articulo> lista) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            sortColumnIndex: _ordenColumna,
            sortAscending: _ordenAscendente,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF4F4F5)),
            headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
            columnSpacing: 22,
            columns: [
              DataColumn(label: const Text('Código'), onSort: _ordenar),
              DataColumn(label: const Text('Artículo'), onSort: _ordenar),
              const DataColumn(label: Text('Tipo')),
              const DataColumn(label: Text('Categoría')),
              DataColumn(label: const Text('Existencia'), numeric: true, onSort: _ordenar),
              const DataColumn(label: Text('Costo unit.'), numeric: true),
              DataColumn(label: const Text('Valor'), numeric: true, onSort: _ordenar),
              const DataColumn(label: Text('Estado')),
              const DataColumn(label: Text('Acciones')),
            ],
            rows: [
              for (final a in lista)
                DataRow(
                  cells: [
                    DataCell(Text(a.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(a.nombre, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    )),
                    DataCell(Text(a.tipo.corto, style: const TextStyle(fontSize: 12))),
                    DataCell(Text(a.categoria, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                    DataCell(Text(a.unidad.formatear(a.existencia), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    DataCell(Text('${formatearDinero(a.costoUnitario)} / ${a.unidad.abreviatura}', style: const TextStyle(fontSize: 12))),
                    DataCell(Text(formatearDinero(a.valorEnAlmacen), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataCell(StatusBadge(label: _estado(a).texto, type: _estado(a).tipo)),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (Sesion.editaAlmacen) ...[
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), tooltip: 'Editar', onPressed: () => _editarArticulo(a)),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                            tooltip: 'Eliminar',
                            onPressed: () => _eliminarArticulo(a),
                          ),
                        ],
                      ],
                    )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTarjetasArticulos(List<Articulo> lista) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: lista.length,
      itemBuilder: (context, i) {
        final a = lista[i];
        final estado = _estado(a);
        return Aparicion(
          indice: i,
          child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFFF1F2F4), shape: BoxShape.circle),
                child: Icon(a.tipo == TipoArticulo.material ? Icons.inventory_2_outlined : Icons.handyman_outlined, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${a.id} • ${a.categoria} • ${a.tipo.corto}',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(a.unidad.formatear(a.existencia), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${formatearDinero(a.costoUnitario)} / ${a.unidad.abreviatura}', style: const TextStyle(fontSize: 12)),
                        StatusBadge(label: estado.texto, type: estado.tipo),
                      ],
                    ),
                  ],
                ),
              ),
              if (Sesion.editaAlmacen) ...[
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20), tooltip: 'Editar', onPressed: () => _editarArticulo(a)),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
                  tooltip: 'Eliminar',
                  onPressed: () => _eliminarArticulo(a),
                ),
              ],
            ],
          ),
          ),
        );
      },
    );
  }

  // =====================================================================
  // VALES (comunes)
  // =====================================================================

  String _etiquetaProyecto(ProyectoTaller p) => '${p.id} • ${p.nombreCamion} (${p.placa})';

  Widget _selectorProyecto({required String? valor, required ValueChanged<String?> onChanged}) {
    final proyectos = _proyectos.activos;
    final valido = proyectos.any((p) => p.id == valor) ? valor : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('proyecto-$valido-${proyectos.length}'),
      initialValue: valido,
      isExpanded: true,
      decoration: AppTheme.inputDecoration(proyectos.isEmpty ? 'No hay proyectos activos' : 'Selecciona el proyecto', icon: Icons.local_shipping_outlined),
      items: [
        for (final p in proyectos) DropdownMenuItem(value: p.id, child: Text(_etiquetaProyecto(p), overflow: TextOverflow.ellipsis)),
      ],
      validator: (v) => v == null ? 'Elige el proyecto' : null,
      onChanged: onChanged,
    );
  }

  Widget _selectorArticulo({
    required TipoArticulo tipo,
    required String? valor,
    required ValueChanged<String?> onChanged,
  }) {
    final opciones = _almacen.articulos.where((a) => a.tipo == tipo && !a.agotado).toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    final valido = opciones.any((a) => a.id == valor) ? valor : null;
    return DropdownButtonFormField<String>(
      key: ValueKey('articulo-${tipo.name}-$valido-${opciones.length}'),
      initialValue: valido,
      isExpanded: true,
      decoration: AppTheme.inputDecoration(
        opciones.isEmpty ? 'No hay ${tipo == TipoArticulo.material ? 'materiales' : 'herramientas'} disponibles' : 'Selecciona',
        icon: tipo == TipoArticulo.material ? Icons.inventory_2_outlined : Icons.handyman_outlined,
      ),
      items: [
        for (final a in opciones)
          DropdownMenuItem(
            value: a.id,
            child: Text('${a.nombre} — disponible: ${a.unidad.formatear(a.existencia)}', overflow: TextOverflow.ellipsis),
          ),
      ],
      validator: (v) => v == null ? 'Elige el artículo' : null,
      onChanged: onChanged,
    );
  }

  Widget _campoCantidad({required TextEditingController controller, required Articulo? articulo}) {
    final unidad = articulo?.unidad ?? UnidadMedida.pieza;
    return TextFormField(
      key: ValueKey('cantidad-${articulo?.id}'),
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: unidad.permiteDecimales),
      inputFormatters: formateadoresCantidad(unidad),
      onChanged: (_) => setState(() {}),
      validator: (v) {
        final n = double.tryParse(v ?? '');
        if (n == null || n <= 0) return 'Ingresa una cantidad mayor a 0';
        if (articulo != null && n > articulo.existencia) return 'Solo hay ${articulo.unidad.formatear(articulo.existencia)}';
        return null;
      },
      decoration: AppTheme.inputDecoration(unidad.permiteDecimales ? 'Ej. 2.5' : 'Ej. 2', icon: Icons.scale_outlined)
          .copyWith(suffixText: unidad.abreviatura),
    );
  }

  Widget _tarjetaFormulario({required String titulo, required String subtitulo, required IconData icono, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                child: Icon(icono, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text(subtitulo, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _etiqueta(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 12),
        child: Text(texto, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
      );

  Widget _botonPrincipal({required String texto, required IconData icono, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icono, color: Colors.white),
        label: Text(texto, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: Colors.grey.shade400,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _tituloLista(String texto, String contador) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Row(
          children: [
            Expanded(child: Text(texto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Text(contador, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );

  // =====================================================================
  // VALES DE MATERIAL (se consume)
  // =====================================================================

  Future<void> _generarValeMaterial() async {
    if (!_formMaterial.currentState!.validate()) return;
    final proyecto = _proyectos.activos.firstWhere((p) => p.id == _proyectoMaterial);
    final articulo = _almacen.articuloPorId(_articuloMaterial!)!;
    final cantidad = double.parse(_cantidadMaterial.text);
    final costoEstimado = cantidad * articulo.costoUnitario;
    final error = await _almacen.registrarValeMaterial(
      proyectoId: proyecto.id,
      proyectoNombre: '${proyecto.nombreCamion} (${proyecto.placa})',
      articulo: articulo,
      cantidad: cantidad,
      entregadoA: _entregadoMaterial.text,
    );
    if (!mounted) return;
    if (error != null) {
      _mensaje(error, error: true);
      return;
    }
    _mensaje('Vale generado: ${articulo.unidad.formatear(cantidad)} de ${articulo.nombre} → ${proyecto.nombreCamion} '
        '(${formatearDinero(costoEstimado)}).');
    setState(() {
      _cantidadMaterial.clear();
      _articuloMaterial = null;
    });
  }

  Future<void> _cancelarValeMaterial(ValeMaterial vale) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Cancelar vale de material',
      message: '${vale.unidad.formatear(vale.cantidad)} de "${vale.articuloNombre}" regresarán al almacén y '
          '${formatearDinero(vale.total)} dejarán de contar en el proyecto.',
      confirmText: 'Sí, cancelar vale',
      isDestructive: true,
      icon: Icons.undo,
    );
    if (!confirmar) return;
    final error = await _almacen.cancelarValeMaterial(vale);
    if (!mounted) return;
    _mensaje(error ?? 'Vale ${vale.id} cancelado. El material regresó al almacén.', error: error != null);
  }

  Widget _buildValesMaterial() {
    final articulo = _articuloMaterial == null ? null : _almacen.articuloPorId(_articuloMaterial!);
    final cantidad = double.tryParse(_cantidadMaterial.text) ?? 0;
    final vales = _almacen.valesMaterial;

    return ContenidoResponsivo(
      anchoMaximo: 760,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!Sesion.registraVales)
            const AvisoSoloLectura('Consulta de vales de material. Solo Almacén, Proyectos y el Administrador pueden generarlos.')
          else
          Form(
            key: _formMaterial,
            child: _tarjetaFormulario(
              titulo: 'Vale de salida de material',
              subtitulo: 'El material se consume y su costo se carga al proyecto.',
              icono: Icons.inventory_2_outlined,
              children: [
                _etiqueta('Proyecto destino *'),
                _selectorProyecto(valor: _proyectoMaterial, onChanged: (v) => setState(() => _proyectoMaterial = v)),
                _etiqueta('Material *'),
                _selectorArticulo(
                  tipo: TipoArticulo.material,
                  valor: _articuloMaterial,
                  onChanged: (v) => setState(() {
                    _articuloMaterial = v;
                    _cantidadMaterial.clear();
                  }),
                ),
                _etiqueta('Cantidad *'),
                _campoCantidad(controller: _cantidadMaterial, articulo: articulo),
                _etiqueta('Entregado a'),
                TextFormField(
                  controller: _entregadoMaterial,
                  decoration: AppTheme.inputDecoration('Nombre de quien recibe (opcional)', icon: Icons.person_outline),
                ),
                if (articulo != null && cantidad > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Costo a cargar al proyecto: ${formatearDinero(cantidad * articulo.costoUnitario)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 18),
                _botonPrincipal(texto: 'Generar vale de material', icono: Icons.receipt_long, onPressed: _generarValeMaterial),
              ],
            ),
          ),
          _tituloLista('Vales de material registrados', '${vales.length}'),
          if (vales.isEmpty)
            const Text('Aún no hay vales de material.', style: TextStyle(color: AppTheme.textSecondary))
          else
            for (final v in vales)
              _filaVale(
                icono: Icons.inventory_2_outlined,
                titulo: '${v.unidad.formatear(v.cantidad)} • ${v.articuloNombre}',
                detalle: '${v.id} • ${v.proyectoNombre}\n${formatearFechaHora(v.fecha)}${v.entregadoA.isEmpty ? '' : ' • Recibió: ${v.entregadoA}'}',
                extra: Text(formatearDinero(v.total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                acciones: [
                  if (Sesion.registraVales)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
                      tooltip: 'Cancelar vale (regresa el material)',
                      onPressed: () => _cancelarValeMaterial(v),
                    ),
                ],
              ),
        ],
      ),
    );
  }

  Widget _filaVale({required IconData icono, required String titulo, required String detalle, Widget? extra, List<Widget> acciones = const []}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Row(
        children: [
          Icon(icono, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(detalle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                if (extra != null) ...[const SizedBox(height: 4), extra],
              ],
            ),
          ),
          ...acciones,
        ],
      ),
    );
  }

  // =====================================================================
  // HERRAMIENTAS (deben volver)
  // =====================================================================

  Future<void> _prestarHerramienta() async {
    if (!_formHerramienta.currentState!.validate()) return;
    final proyecto = _proyectos.activos.firstWhere((p) => p.id == _proyectoHerramienta);
    final articulo = _almacen.articuloPorId(_articuloHerramienta!)!;
    final cantidad = double.parse(_cantidadHerramienta.text);
    final error = await _almacen.prestarHerramienta(
      proyectoId: proyecto.id,
      proyectoNombre: '${proyecto.nombreCamion} (${proyecto.placa})',
      articulo: articulo,
      cantidad: cantidad,
      entregadoA: _entregadoHerramienta.text,
    );
    if (!mounted) return;
    if (error != null) {
      _mensaje(error, error: true);
      return;
    }
    _mensaje('Préstamo registrado: ${articulo.unidad.formatear(cantidad)} de ${articulo.nombre}. Debe regresar al almacén.');
    setState(() {
      _cantidadHerramienta.text = '1';
      _articuloHerramienta = null;
    });
  }

  Future<void> _registrarDevolucion(ValeHerramienta vale) async {
    final estado = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Devolución: ${vale.articuloNombre}'),
        children: [
          for (final opcion in ['Buen estado', 'Con daño', 'Incompleta'])
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, opcion),
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(opcion, style: const TextStyle(fontSize: 15))),
            ),
        ],
      ),
    );
    if (estado == null) return;
    final error = await _almacen.registrarDevolucion(vale, estado);
    if (!mounted) return;
    _mensaje(error ?? 'Devolución registrada (${estado.toLowerCase()}).', error: error != null);
  }

  Future<void> _eliminarValeHerramienta(ValeHerramienta vale) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar vale',
      message: vale.devuelto
          ? '¿Eliminar el registro ${vale.id} del historial?'
          : 'La herramienta se dará por regresada al almacén y se eliminará el vale ${vale.id}.',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirmar) return;
    final error = await _almacen.eliminarValeHerramienta(vale);
    if (!mounted) return;
    _mensaje(error ?? 'Vale ${vale.id} eliminado.', error: error != null);
  }

  Widget _buildHerramientas() {
    final articulo = _articuloHerramienta == null ? null : _almacen.articuloPorId(_articuloHerramienta!);
    final prestadas = _almacen.valesHerramienta.where((v) => !v.devuelto).toList();
    final devueltas = _almacen.valesHerramienta.where((v) => v.devuelto).toList();

    return ContenidoResponsivo(
      anchoMaximo: 760,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!Sesion.registraVales)
            const AvisoSoloLectura('Consulta de préstamos de herramienta. Solo Almacén, Proyectos y el Administrador pueden registrarlos.')
          else
          Form(
            key: _formHerramienta,
            child: _tarjetaFormulario(
              titulo: 'Vale de herramienta',
              subtitulo: 'La herramienta se presta al proyecto y DEBE regresar al almacén.',
              icono: Icons.handyman_outlined,
              children: [
                _etiqueta('Proyecto *'),
                _selectorProyecto(valor: _proyectoHerramienta, onChanged: (v) => setState(() => _proyectoHerramienta = v)),
                _etiqueta('Herramienta *'),
                _selectorArticulo(
                  tipo: TipoArticulo.herramienta,
                  valor: _articuloHerramienta,
                  onChanged: (v) => setState(() {
                    _articuloHerramienta = v;
                    _cantidadHerramienta.text = '1';
                  }),
                ),
                _etiqueta('Cantidad *'),
                _campoCantidad(controller: _cantidadHerramienta, articulo: articulo),
                _etiqueta('Responsable que la recibe *'),
                TextFormField(
                  controller: _entregadoHerramienta,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Indica quién se hace responsable' : null,
                  decoration: AppTheme.inputDecoration('Nombre del mecánico o responsable', icon: Icons.engineering_outlined),
                ),
                const SizedBox(height: 18),
                _botonPrincipal(texto: 'Registrar préstamo', icono: Icons.outbox_outlined, onPressed: _prestarHerramienta),
              ],
            ),
          ),
          _tituloLista('Prestadas — pendientes de volver', '${prestadas.length}'),
          if (prestadas.isEmpty)
            const Text('No hay herramientas prestadas.', style: TextStyle(color: AppTheme.textSecondary))
          else
            for (final v in prestadas)
              _filaVale(
                icono: Icons.handyman_outlined,
                titulo: '${v.unidad.formatear(v.cantidad)} • ${v.articuloNombre}',
                detalle: '${v.id} • ${v.proyectoNombre}\nSalió ${formatearFechaHora(v.fechaSalida)} • Responsable: ${v.entregadoA}',
                extra: const StatusBadge(label: 'DEBE VOLVER', type: BadgeType.warning),
                acciones: [
                  if (Sesion.registraVales) ...[
                    IconButton(
                      icon: const Icon(Icons.assignment_return_outlined, size: 20, color: AppTheme.success),
                      tooltip: 'Registrar devolución',
                      onPressed: () => _registrarDevolucion(v),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
                      tooltip: 'Eliminar vale',
                      onPressed: () => _eliminarValeHerramienta(v),
                    ),
                  ],
                ],
              ),
          _tituloLista('Historial de devoluciones', '${devueltas.length}'),
          if (devueltas.isEmpty)
            const Text('Sin devoluciones registradas.', style: TextStyle(color: AppTheme.textSecondary))
          else
            for (final v in devueltas)
              _filaVale(
                icono: Icons.assignment_turned_in_outlined,
                titulo: '${v.unidad.formatear(v.cantidad)} • ${v.articuloNombre}',
                detalle: '${v.id} • ${v.proyectoNombre}\nVolvió ${formatearFechaHora(v.fechaDevolucion!)} • ${v.estadoDevolucion}',
                acciones: [
                  if (Sesion.registraVales)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
                      tooltip: 'Eliminar del historial',
                      onPressed: () => _eliminarValeHerramienta(v),
                    ),
                ],
              ),
        ],
      ),
    );
  }

  // =====================================================================
  // ENTREGA DE PLACAS / RESGUARDOS
  // =====================================================================

  String _busquedaResguardo = '';

  Future<void> _registrarSalida(RegistroResguardo r) async {
    final quien = TextEditingController();
    final notas = TextEditingController();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Salida de almacén: ${r.empresa} ${r.numeroUnidad}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Se entrega: ${r.objetos}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(controller: quien, autofocus: true, decoration: AppTheme.inputDecoration('¿A quién se le entrega?', icon: Icons.person_outline)),
            const SizedBox(height: 10),
            TextField(controller: notas, decoration: AppTheme.inputDecoration('Notas (opcional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Registrar salida')),
        ],
      ),
    );
    final nombre = quien.text;
    final texto = notas.text;
    quien.dispose();
    notas.dispose();
    if (confirmado != true) return;
    final error = await _almacen.registrarSalidaResguardo(r, entregadoA: nombre, notas: texto);
    if (!mounted) return;
    _mensaje(error ?? 'Salida registrada.', error: error != null);
  }

  Future<void> _eliminarResguardo(RegistroResguardo r) async {
    final confirmar = await ConfirmDialog.show(
      context: context,
      title: 'Eliminar registro',
      message: '¿Eliminar el registro de ${r.empresa} ${r.numeroUnidad}?',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirmar) return;
    final error = await _almacen.eliminarResguardo(r);
    if (!mounted) return;
    _mensaje(error ?? 'Registro eliminado.', error: error != null);
  }

  Widget _buildResguardos() {
    final q = _busquedaResguardo.toLowerCase();
    bool coincide(RegistroResguardo r) =>
        q.isEmpty ||
        r.empresa.toLowerCase().contains(q) ||
        r.numeroUnidad.toLowerCase().contains(q) ||
        r.tipoUnidad.toLowerCase().contains(q) ||
        r.objetos.toLowerCase().contains(q) ||
        r.operador.toLowerCase().contains(q);
    final enAlmacen = _almacen.resguardos.where((r) => r.enAlmacen && coincide(r)).toList();
    final entregados = _almacen.resguardos.where((r) => !r.enAlmacen && coincide(r)).toList();

    return ContenidoResponsivo(
      anchoMaximo: 900,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _busquedaResguardo = v),
                  decoration: AppTheme.inputDecoration('Buscar empresa, unidad, operador...', icon: Icons.search),
                ),
              ),
              if (Sesion.editaAlmacen) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => mostrarFormularioResguardo(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Registrar entrega', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              ],
            ],
          ),
          _tituloLista('En almacén', '${enAlmacen.length}'),
          if (enAlmacen.isEmpty)
            const Text('No hay placas ni piezas en resguardo.', style: TextStyle(color: AppTheme.textSecondary))
          else
            for (final r in enAlmacen) _tarjetaResguardo(r),
          _tituloLista('Entregados (historial)', '${entregados.length}'),
          if (entregados.isEmpty)
            const Text('Sin salidas registradas.', style: TextStyle(color: AppTheme.textSecondary))
          else
            for (final r in entregados) _tarjetaResguardo(r),
        ],
      ),
    );
  }

  Widget _tarjetaResguardo(RegistroResguardo r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: r.enAlmacen ? AppTheme.border : const Color(0xFFF1F2F4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFF1F2F4), shape: BoxShape.circle),
            child: Icon(r.enAlmacen ? Icons.inventory_outlined : Icons.assignment_turned_in_outlined, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r.empresa} • ${r.tipoUnidad.isEmpty ? 'Unidad' : r.tipoUnidad} ${r.numeroUnidad}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(r.objetos, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Ingresó ${formatearFecha(r.fechaIngreso)} • Entregó ${r.operador}'
                  '${r.enAlmacen ? ' • ${r.diasEnAlmacen} días en almacén' : ''}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (!r.enAlmacen)
                  Text(
                    'Salió ${formatearFecha(r.fechaSalida!)} • Se entregó a ${r.entregadoA}${(r.notasSalida ?? '').isNotEmpty ? ' • ${r.notasSalida}' : ''}',
                    style: const TextStyle(color: AppTheme.success, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                if (r.firma != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(8)),
                    child: Image.memory(r.firma!, fit: BoxFit.contain),
                  ),
                ],
              ],
            ),
          ),
          if (Sesion.editaAlmacen)
            Column(
              children: [
                if (r.enAlmacen)
                  IconButton(
                    icon: const Icon(Icons.outbox_outlined, color: AppTheme.success),
                    tooltip: 'Registrar salida de almacén',
                    onPressed: () => _registrarSalida(r),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textMuted),
                  tooltip: 'Eliminar',
                  onPressed: () => _eliminarResguardo(r),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
