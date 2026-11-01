/// Modelos del almacén: artículos del catálogo y vales de salida.
library;

/// Cómo se mide un artículo. Las unidades a granel aceptan decimales (2.5 kg, 0.75 L).
enum UnidadMedida { pieza, kilogramo, litro, metro, juego, caja }

extension UnidadMedidaTexto on UnidadMedida {
  String get nombre => switch (this) {
        UnidadMedida.pieza => 'Pieza / unidad',
        UnidadMedida.kilogramo => 'Kilogramo',
        UnidadMedida.litro => 'Litro',
        UnidadMedida.metro => 'Metro',
        UnidadMedida.juego => 'Juego / kit',
        UnidadMedida.caja => 'Caja',
      };

  String get abreviatura => switch (this) {
        UnidadMedida.pieza => 'pza',
        UnidadMedida.kilogramo => 'kg',
        UnidadMedida.litro => 'L',
        UnidadMedida.metro => 'm',
        UnidadMedida.juego => 'jgo',
        UnidadMedida.caja => 'caja',
      };

  static UnidadMedida desdeTexto(String? texto) =>
      UnidadMedida.values.firstWhere((u) => u.name == texto, orElse: () => UnidadMedida.pieza);

  bool get permiteDecimales => this == UnidadMedida.kilogramo || this == UnidadMedida.litro || this == UnidadMedida.metro;

  /// 3 → "3 pza", 2.5 → "2.5 kg", 2.0 kg → "2 kg"
  String formatear(double cantidad) {
    final texto = cantidad == cantidad.roundToDouble()
        ? cantidad.toStringAsFixed(0)
        : cantidad.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
    return '$texto $abreviatura';
  }
}

/// Material: se consume y su costo se carga al proyecto.
/// Herramienta: se presta a un proyecto y debe regresar al almacén.
enum TipoArticulo { material, herramienta }

extension TipoArticuloTexto on TipoArticulo {
  String get nombre => this == TipoArticulo.material ? 'Material (se consume)' : 'Herramienta (debe volver)';
  String get corto => this == TipoArticulo.material ? 'Material' : 'Herramienta';

  /// Nombre que usa el backend.
  String get api => corto;

  static TipoArticulo desdeTexto(String? texto) => texto == 'Herramienta' ? TipoArticulo.herramienta : TipoArticulo.material;
}

double _decimal(Object? v) => v == null ? 0 : (v as num).toDouble();
DateTime _fecha(Object? v) => v == null ? DateTime.now() : DateTime.parse(v as String);

class Articulo {
  final String id;
  int? serverId;
  int? categoriaId;
  String nombre;
  String categoria;
  TipoArticulo tipo;
  UnidadMedida unidad;

  /// Cantidad físicamente en el almacén (sin contar herramientas prestadas).
  double existencia;
  double costoUnitario;

  Articulo({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.tipo,
    required this.unidad,
    required this.existencia,
    required this.costoUnitario,
    this.serverId,
    this.categoriaId,
  });

  factory Articulo.fromJson(Map<String, dynamic> j) => Articulo(
        id: j['codigo'] as String,
        serverId: (j['id'] as num).toInt(),
        nombre: j['nombre'] as String? ?? '',
        categoriaId: (j['categoriaId'] as num?)?.toInt(),
        categoria: j['categoria'] as String? ?? '',
        tipo: TipoArticuloTexto.desdeTexto(j['tipo'] as String?),
        unidad: UnidadMedidaTexto.desdeTexto(j['unidad'] as String?),
        existencia: _decimal(j['existencia']),
        costoUnitario: _decimal(j['costoUnitario']),
      );

  bool get agotado => existencia <= 0;
  bool get bajoStock => !agotado && existencia < 5;
  double get valorEnAlmacen => existencia * costoUnitario;
}

/// Salida de material consumible hacia un proyecto. Su costo cuenta como dinero invertido.
class ValeMaterial {
  final String id;
  final int? serverId;
  final String proyectoId;
  final String proyectoNombre;
  final String articuloId;
  final String articuloNombre;
  final UnidadMedida unidad;
  final double cantidad;
  final double costoUnitario;
  final String entregadoA;
  final DateTime fecha;

  ValeMaterial({
    required this.id,
    required this.proyectoId,
    required this.proyectoNombre,
    required this.articuloId,
    required this.articuloNombre,
    required this.unidad,
    required this.cantidad,
    required this.costoUnitario,
    required this.entregadoA,
    required this.fecha,
    this.serverId,
  });

  factory ValeMaterial.fromJson(Map<String, dynamic> j) => ValeMaterial(
        id: j['codigo'] as String,
        serverId: (j['id'] as num).toInt(),
        proyectoId: j['proyectoCodigo'] as String? ?? '',
        proyectoNombre: j['proyectoNombre'] as String? ?? '',
        articuloId: 'ALM-${((j['articuloId'] as num?)?.toInt() ?? 0).toString().padLeft(3, '0')}',
        articuloNombre: j['articuloNombre'] as String? ?? '',
        unidad: UnidadMedidaTexto.desdeTexto(j['unidad'] as String?),
        cantidad: _decimal(j['cantidad']),
        costoUnitario: _decimal(j['costoUnitario']),
        entregadoA: j['entregadoA'] as String? ?? '',
        fecha: _fecha(j['fecha']),
      );

  double get total => cantidad * costoUnitario;
}

/// Préstamo de herramienta a un proyecto. Queda abierto hasta registrar su devolución.
class ValeHerramienta {
  final String id;
  final int? serverId;
  final String proyectoId;
  final String proyectoNombre;
  final String articuloId;
  final String articuloNombre;
  final UnidadMedida unidad;
  final double cantidad;
  final String entregadoA;
  final DateTime fechaSalida;
  DateTime? fechaDevolucion;
  String? estadoDevolucion;

  ValeHerramienta({
    required this.id,
    required this.proyectoId,
    required this.proyectoNombre,
    required this.articuloId,
    required this.articuloNombre,
    required this.unidad,
    required this.cantidad,
    required this.entregadoA,
    required this.fechaSalida,
    this.serverId,
    this.fechaDevolucion,
    this.estadoDevolucion,
  });

  factory ValeHerramienta.fromJson(Map<String, dynamic> j) => ValeHerramienta(
        id: j['codigo'] as String,
        serverId: (j['id'] as num).toInt(),
        proyectoId: j['proyectoCodigo'] as String? ?? '',
        proyectoNombre: j['proyectoNombre'] as String? ?? '',
        articuloId: j['articuloId'] == null ? '' : 'ALM-${(j['articuloId'] as num).toInt().toString().padLeft(3, '0')}',
        articuloNombre: j['articuloNombre'] as String? ?? '',
        unidad: UnidadMedidaTexto.desdeTexto(j['unidad'] as String?),
        cantidad: _decimal(j['cantidad']),
        entregadoA: j['entregadoA'] as String? ?? '',
        fechaSalida: _fecha(j['fechaSalida']),
        fechaDevolucion: j['fechaDevolucion'] == null ? null : DateTime.parse(j['fechaDevolucion'] as String),
        estadoDevolucion: j['estadoDevolucion'] as String?,
      );

  bool get devuelto => fechaDevolucion != null;
}
