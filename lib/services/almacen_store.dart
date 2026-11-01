import 'package:flutter/foundation.dart';
import '../models/almacen_inventario.dart';
import '../models/resguardo.dart';
import 'api_client.dart';
import 'proyectos_store.dart';
import 'sesion.dart';

/// Estado compartido del almacén (un solo almacén físico): categorías, catálogo de artículos
/// y vales de salida. En modo demo trabaja en memoria; con sesión real usa /api/Almacen y /api/Herramientas.
///
/// Los métodos que pueden fallar devuelven un mensaje de error, o null si todo salió bien.
class AlmacenStore extends ChangeNotifier {
  AlmacenStore._() {
    _cargarEjemplos();
  }

  static final AlmacenStore instancia = AlmacenStore._();

  final ApiClient _api = ApiClient();
  final List<String> _categorias = [];
  final Map<String, int> _idCategoria = {};
  final List<Articulo> _articulos = [];
  final List<ValeMaterial> _valesMaterial = [];
  final List<ValeHerramienta> _valesHerramienta = [];
  final List<RegistroResguardo> _resguardos = [];
  int _consecutivoArticulo = 0;
  int _consecutivoVale = 0;

  List<String> get categorias => List.unmodifiable(_categorias);
  List<Articulo> get articulos => List.unmodifiable(_articulos);
  List<ValeMaterial> get valesMaterial => List.unmodifiable(_valesMaterial.reversed);
  List<ValeHerramienta> get valesHerramienta => List.unmodifiable(_valesHerramienta.reversed);
  List<RegistroResguardo> get resguardos => List.unmodifiable(_resguardos);

  String siguienteIdArticulo() => 'ALM-${(_consecutivoArticulo + 1).toString().padLeft(3, '0')}';

  Articulo? articuloPorId(String id) {
    for (final a in _articulos) {
      if (a.id == id) return a;
    }
    return null;
  }

  int articulosEnCategoria(String categoria) => _articulos.where((a) => a.categoria == categoria).length;

  double cantidadPrestada(String articuloId) => _valesHerramienta
      .where((v) => v.articuloId == articuloId && !v.devuelto)
      .fold(0.0, (suma, v) => suma + v.cantidad);

  // ---------------------------------------------------------------- Carga (modo API)

  Future<String?> cargar() async {
    try {
      final resultados = await Future.wait([
        _api.get('/Almacen/categorias'),
        _api.get('/Almacen/articulos'),
        _api.get('/Almacen/vales-material'),
        _api.get('/Herramientas'),
        _api.get('/Almacen/resguardos'),
      ]);
      Map<String, dynamic> m(Object? e) => Map<String, dynamic>.from(e as Map);

      _categorias.clear();
      _idCategoria.clear();
      for (final c in (resultados[0] as List).map(m)) {
        _categorias.add(c['nombre'] as String);
        _idCategoria[c['nombre'] as String] = (c['id'] as num).toInt();
      }
      _articulos
        ..clear()
        ..addAll((resultados[1] as List).map((e) => Articulo.fromJson(m(e))));
      // El backend los entrega del más reciente al más antiguo; aquí se guardan en orden de registro
      _valesMaterial
        ..clear()
        ..addAll((resultados[2] as List).map((e) => ValeMaterial.fromJson(m(e))).toList().reversed);
      _valesHerramienta
        ..clear()
        ..addAll((resultados[3] as List).map((e) => ValeHerramienta.fromJson(m(e))).toList().reversed);
      _resguardos
        ..clear()
        ..addAll((resultados[4] as List).map((e) => RegistroResguardo.fromJson(m(e))));
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.mensaje;
    }
  }

  void reiniciarDemo() {
    _categorias.clear();
    _idCategoria.clear();
    _articulos.clear();
    _valesMaterial.clear();
    _valesHerramienta.clear();
    _resguardos.clear();
    _consecutivoArticulo = 0;
    _consecutivoVale = 0;
    _cargarEjemplos();
    notifyListeners();
  }

  /// Ejecuta una operación contra la API y, si sale bien, recarga el almacén.
  Future<String?> _enApi(Future<dynamic> Function() llamada) async {
    try {
      await llamada();
    } on ApiException catch (e) {
      return e.mensaje;
    }
    return cargar();
  }

  int? _serverId(String codigo) => int.tryParse(codigo.split('-').last);

  // ---------------------------------------------------------------- Categorías

  Future<String?> agregarCategoria(String nombre) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe el nombre de la categoría.';
    if (_existeCategoria(limpio)) return 'La categoría "$limpio" ya existe.';
    if (!Sesion.modoDemo) return _enApi(() => _api.post('/Almacen/categorias', {'nombre': limpio}));

    _categorias.add(limpio);
    _categorias.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    notifyListeners();
    return null;
  }

  Future<String?> renombrarCategoria(String actual, String nuevo) async {
    final limpio = nuevo.trim();
    if (limpio.isEmpty) return 'Escribe el nombre de la categoría.';
    if (limpio.toLowerCase() != actual.toLowerCase() && _existeCategoria(limpio)) return 'La categoría "$limpio" ya existe.';
    if (!Sesion.modoDemo) {
      return _enApi(() => _api.put('/Almacen/categorias/${_idCategoria[actual]}', {'nombre': limpio}));
    }

    final i = _categorias.indexOf(actual);
    if (i < 0) return 'La categoría ya no existe.';
    _categorias[i] = limpio;
    for (final a in _articulos.where((a) => a.categoria == actual)) {
      a.categoria = limpio;
    }
    _categorias.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    notifyListeners();
    return null;
  }

  Future<String?> eliminarCategoria(String categoria) async {
    final enUso = articulosEnCategoria(categoria);
    if (enUso > 0) {
      return 'No se puede eliminar "$categoria": la usan $enUso artículo(s). Cámbialos de categoría primero.';
    }
    if (!Sesion.modoDemo) return _enApi(() => _api.delete('/Almacen/categorias/${_idCategoria[categoria]}'));

    _categorias.remove(categoria);
    notifyListeners();
    return null;
  }

  bool _existeCategoria(String nombre) => _categorias.any((c) => c.toLowerCase() == nombre.toLowerCase());

  // ---------------------------------------------------------------- Artículos

  Future<String?> guardarArticulo({
    Articulo? existente,
    required String nombre,
    required String categoria,
    required TipoArticulo tipo,
    required UnidadMedida unidad,
    required double existencia,
    required double costoUnitario,
  }) async {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe el nombre del artículo.';
    if (!_categorias.contains(categoria)) return 'Selecciona una categoría válida.';
    if (existencia < 0 || costoUnitario < 0) return 'La existencia y el costo no pueden ser negativos.';
    if (!unidad.permiteDecimales && existencia != existencia.roundToDouble()) {
      return 'Un artículo por ${unidad.nombre.toLowerCase()} no puede tener cantidades con decimales.';
    }
    final repetido = _articulos.any((a) => !identical(a, existente) && a.nombre.toLowerCase() == limpio.toLowerCase());
    if (repetido) return 'Ya existe un artículo llamado "$limpio".';
    if (existente != null && existente.tipo != tipo && cantidadPrestada(existente.id) > 0) {
      return 'No se puede cambiar el tipo: hay herramientas de este artículo prestadas.';
    }

    if (!Sesion.modoDemo) {
      final cuerpo = {
        'nombre': limpio,
        'categoriaId': _idCategoria[categoria],
        'tipo': tipo.api,
        'unidad': unidad.name,
        'existencia': existencia,
        'costoUnitario': costoUnitario,
      };
      return _enApi(() => existente == null
          ? _api.post('/Almacen/articulos', cuerpo)
          : _api.put('/Almacen/articulos/${existente.serverId}', cuerpo));
    }

    if (existente == null) {
      _consecutivoArticulo++;
      _articulos.insert(
        0,
        Articulo(
          id: 'ALM-${_consecutivoArticulo.toString().padLeft(3, '0')}',
          serverId: _consecutivoArticulo,
          nombre: limpio,
          categoria: categoria,
          tipo: tipo,
          unidad: unidad,
          existencia: existencia,
          costoUnitario: costoUnitario,
        ),
      );
    } else {
      existente
        ..nombre = limpio
        ..categoria = categoria
        ..tipo = tipo
        ..unidad = unidad
        ..existencia = existencia
        ..costoUnitario = costoUnitario;
    }
    notifyListeners();
    return null;
  }

  Future<String?> eliminarArticulo(Articulo articulo) async {
    if (cantidadPrestada(articulo.id) > 0) {
      return 'No se puede eliminar "${articulo.nombre}": tiene herramientas prestadas sin devolver.';
    }
    if (!Sesion.modoDemo) return _enApi(() => _api.delete('/Almacen/articulos/${articulo.serverId}'));

    _articulos.remove(articulo);
    notifyListeners();
    return null;
  }

  // ---------------------------------------------------------------- Vales de material

  Future<String?> registrarValeMaterial({
    required String proyectoId,
    required String proyectoNombre,
    required Articulo articulo,
    required double cantidad,
    required String entregadoA,
  }) async {
    final error = _validarSalida(articulo, cantidad, TipoArticulo.material);
    if (error != null) return error;

    if (!Sesion.modoDemo) {
      final proyecto = ProyectosStore.instancia.porId(proyectoId);
      return _enApi(() => _api.post('/Almacen/vales-material', {
            'proyectoId': proyecto?.serverId,
            'articuloId': articulo.serverId,
            'cantidad': cantidad,
            'entregadoA': entregadoA.trim(),
          }));
    }

    articulo.existencia -= cantidad;
    _valesMaterial.add(ValeMaterial(
      id: _siguienteIdVale('VM'),
      proyectoId: proyectoId,
      proyectoNombre: proyectoNombre,
      articuloId: articulo.id,
      articuloNombre: articulo.nombre,
      unidad: articulo.unidad,
      cantidad: cantidad,
      costoUnitario: articulo.costoUnitario,
      entregadoA: entregadoA.trim(),
      fecha: DateTime.now(),
    ));
    notifyListeners();
    return null;
  }

  /// Cancela el vale: el material regresa al almacén y deja de contar en el proyecto.
  Future<String?> cancelarValeMaterial(ValeMaterial vale) async {
    if (!Sesion.modoDemo) return _enApi(() => _api.delete('/Almacen/vales-material/${vale.serverId ?? _serverId(vale.id)}'));

    articuloPorId(vale.articuloId)?.existencia += vale.cantidad;
    _valesMaterial.remove(vale);
    notifyListeners();
    return null;
  }

  List<ValeMaterial> valesMaterialDe(String proyectoId) =>
      _valesMaterial.where((v) => v.proyectoId == proyectoId).toList().reversed.toList();

  double totalInvertido(String proyectoId) =>
      _valesMaterial.where((v) => v.proyectoId == proyectoId).fold(0.0, (suma, v) => suma + v.total);

  // ---------------------------------------------------------------- Vales de herramienta

  Future<String?> prestarHerramienta({
    required String proyectoId,
    required String proyectoNombre,
    required Articulo articulo,
    required double cantidad,
    required String entregadoA,
  }) async {
    final error = _validarSalida(articulo, cantidad, TipoArticulo.herramienta);
    if (error != null) return error;
    if (entregadoA.trim().isEmpty) return 'Indica a quién se le entrega la herramienta.';

    if (!Sesion.modoDemo) {
      final proyecto = ProyectosStore.instancia.porId(proyectoId);
      return _enApi(() => _api.post('/Herramientas/prestar', {
            'proyectoId': proyecto?.serverId,
            'articuloId': articulo.serverId,
            'cantidad': cantidad,
            'entregadoA': entregadoA.trim(),
          }));
    }

    articulo.existencia -= cantidad;
    _valesHerramienta.add(ValeHerramienta(
      id: _siguienteIdVale('VH'),
      proyectoId: proyectoId,
      proyectoNombre: proyectoNombre,
      articuloId: articulo.id,
      articuloNombre: articulo.nombre,
      unidad: articulo.unidad,
      cantidad: cantidad,
      entregadoA: entregadoA.trim(),
      fechaSalida: DateTime.now(),
    ));
    notifyListeners();
    return null;
  }

  Future<String?> registrarDevolucion(ValeHerramienta vale, String estado) async {
    if (vale.devuelto) return null;
    if (!Sesion.modoDemo) {
      return _enApi(() => _api.post('/Herramientas/${vale.serverId ?? _serverId(vale.id)}/devolver', {'estado': estado}));
    }

    vale
      ..fechaDevolucion = DateTime.now()
      ..estadoDevolucion = estado;
    articuloPorId(vale.articuloId)?.existencia += vale.cantidad;
    notifyListeners();
    return null;
  }

  /// Elimina el vale. Si la herramienta seguía prestada, regresa al almacén.
  Future<String?> eliminarValeHerramienta(ValeHerramienta vale) async {
    if (!Sesion.modoDemo) return _enApi(() => _api.delete('/Herramientas/${vale.serverId ?? _serverId(vale.id)}'));

    if (!vale.devuelto) articuloPorId(vale.articuloId)?.existencia += vale.cantidad;
    _valesHerramienta.remove(vale);
    notifyListeners();
    return null;
  }

  List<ValeHerramienta> herramientasDe(String proyectoId) =>
      _valesHerramienta.where((v) => v.proyectoId == proyectoId).toList().reversed.toList();

  // ---------------------------------------------------------------- Entrega de placas / resguardos

  Future<String?> registrarResguardo({
    required String empresa,
    required String tipoUnidad,
    required String numeroUnidad,
    required String objetos,
    required DateTime fechaIngreso,
    required String operador,
    Uint8List? firma,
  }) async {
    if (empresa.trim().isEmpty) return 'Indica la empresa.';
    if (objetos.trim().isEmpty) return 'Indica qué se entrega al almacén.';
    if (operador.trim().isEmpty) return 'Indica el nombre del operador que entrega.';
    final registro = RegistroResguardo(
      id: _resguardos.isEmpty ? 1 : _resguardos.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1,
      empresa: empresa.trim(),
      tipoUnidad: tipoUnidad.trim(),
      numeroUnidad: numeroUnidad.trim().isEmpty ? 'S/N' : numeroUnidad.trim(),
      objetos: objetos.trim(),
      fechaIngreso: fechaIngreso,
      operador: operador.trim(),
      firma: firma,
    );
    if (!Sesion.modoDemo) return _enApi(() => _api.post('/Almacen/resguardos', registro.toJson()));
    _resguardos.insert(0, registro);
    notifyListeners();
    return null;
  }

  Future<String?> registrarSalidaResguardo(RegistroResguardo r, {required String entregadoA, String notas = ''}) async {
    if (!r.enAlmacen) return 'Ya se registró la salida.';
    if (entregadoA.trim().isEmpty) return 'Indica a quién se le entrega.';
    if (!Sesion.modoDemo) {
      return _enApi(() => _api.post('/Almacen/resguardos/${r.id}/salida', {'entregadoA': entregadoA.trim(), 'notas': notas.trim()}));
    }
    r
      ..fechaSalida = DateTime.now()
      ..entregadoA = entregadoA.trim()
      ..notasSalida = notas.trim();
    notifyListeners();
    return null;
  }

  Future<String?> eliminarResguardo(RegistroResguardo r) async {
    if (!Sesion.modoDemo) return _enApi(() => _api.delete('/Almacen/resguardos/${r.id}'));
    _resguardos.remove(r);
    notifyListeners();
    return null;
  }

  // ---------------------------------------------------------------- Auxiliares

  String? _validarSalida(Articulo articulo, double cantidad, TipoArticulo tipoEsperado) {
    if (articulo.tipo != tipoEsperado) {
      return tipoEsperado == TipoArticulo.material
          ? '"${articulo.nombre}" es una herramienta: usa el vale de herramientas.'
          : '"${articulo.nombre}" es un material: usa el vale de material.';
    }
    if (cantidad <= 0) return 'La cantidad debe ser mayor a cero.';
    if (!articulo.unidad.permiteDecimales && cantidad != cantidad.roundToDouble()) {
      return 'Este artículo se entrega por ${articulo.unidad.nombre.toLowerCase()}: usa cantidades enteras.';
    }
    if (cantidad > articulo.existencia) {
      return 'Solo hay ${articulo.unidad.formatear(articulo.existencia)} de "${articulo.nombre}" en almacén.';
    }
    return null;
  }

  String _siguienteIdVale(String prefijo) {
    _consecutivoVale++;
    return '$prefijo-${_consecutivoVale.toString().padLeft(4, '0')}';
  }

  void _cargarEjemplos() {
    _categorias.addAll(['Carrocería', 'Eléctrico', 'Fluidos', 'Frenos', 'Herramientas', 'Motor', 'Suspensión', 'Transmisión']);

    void agregar(String nombre, String categoria, TipoArticulo tipo, UnidadMedida unidad, double existencia, double costo) {
      _consecutivoArticulo++;
      _articulos.add(Articulo(
        id: 'ALM-${_consecutivoArticulo.toString().padLeft(3, '0')}',
        serverId: _consecutivoArticulo,
        nombre: nombre,
        categoria: categoria,
        tipo: tipo,
        unidad: unidad,
        existencia: existencia,
        costoUnitario: costo,
      ));
    }

    agregar('Balatas de freno cerámicas', 'Frenos', TipoArticulo.material, UnidadMedida.juego, 14, 1250);
    agregar('Aceite de motor sintético 15W40', 'Fluidos', TipoArticulo.material, UnidadMedida.litro, 50, 320);
    agregar('Filtro de aire Kenworth T680', 'Motor', TipoArticulo.material, UnidadMedida.pieza, 3, 890);
    agregar('Kit de embrague reforzado', 'Transmisión', TipoArticulo.material, UnidadMedida.juego, 2, 8400);
    agregar('Amortiguador delantero Volvo FH', 'Suspensión', TipoArticulo.material, UnidadMedida.pieza, 0, 3100);
    agregar('Soldadura de microalambre', 'Carrocería', TipoArticulo.material, UnidadMedida.kilogramo, 12.5, 180);
    agregar('Martillo de bola 32 oz', 'Herramientas', TipoArticulo.herramienta, UnidadMedida.pieza, 6, 450);
    agregar('Llave de impacto neumática 1/2"', 'Herramientas', TipoArticulo.herramienta, UnidadMedida.pieza, 3, 3800);
    agregar('Gato hidráulico 20 t', 'Herramientas', TipoArticulo.herramienta, UnidadMedida.pieza, 2, 5200);

    final hoy = DateTime.now();
    _resguardos.addAll([
      RegistroResguardo(id: 3, empresa: 'TGL', tipoUnidad: 'Tanque', numeroUnidad: '#184', objetos: 'Placas',
          fechaIngreso: hoy.subtract(const Duration(days: 2)), operador: 'Juan Castro'),
      RegistroResguardo(id: 2, empresa: 'Álvaro Valdivia', tipoUnidad: 'Tolva', numeroUnidad: 'S/N',
          objetos: 'Válvula de descarga verificada y plafones chicos', fechaIngreso: hoy.subtract(const Duration(days: 2)), operador: 'Rafa'),
      RegistroResguardo(id: 1, empresa: 'Lala', tipoUnidad: 'CS', numeroUnidad: '275', objetos: 'Placa logotipo',
          fechaIngreso: hoy.subtract(const Duration(days: 17)), operador: 'Luis Mascorro',
          fechaSalida: hoy.subtract(const Duration(days: 5)), entregadoA: 'Rafa'),
    ]);
  }
}
