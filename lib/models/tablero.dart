// Modelos del tablero de inicio del dashboard.

DateTime? _fecha(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();

/// Solo la parte de fecha (sin hora), para comparar días.
DateTime soloFecha(DateTime f) => DateTime(f.year, f.month, f.day);

/// Unidad (camión) que debe entregarse en la semana.
/// Sale de un proyecto existente ([esProyecto]) o la captura a mano el Admin.
class EntregaSemana {
  int id;
  String unidad;
  String? cliente;
  DateTime fechaEntrega;
  String? notas;

  /// Manual: la marcó el Admin. Proyecto: el proyecto ya terminó todas sus etapas.
  bool entregada;
  String? creadoPor;

  /// "proyecto" o "manual".
  final String origen;

  /// Id del proyecto en el servidor (solo origen "proyecto").
  final int? proyectoId;

  /// Código del proyecto: PC-001 / PA-001.
  final String? codigo;

  /// El Admin la quitó del tablero (solo la ve el Admin, para poder regresarla).
  bool oculta;

  EntregaSemana({
    required this.id,
    required this.unidad,
    this.cliente,
    required this.fechaEntrega,
    this.notas,
    this.entregada = false,
    this.creadoPor,
    this.origen = 'manual',
    this.proyectoId,
    this.codigo,
    this.oculta = false,
  });

  bool get esProyecto => origen == 'proyecto';

  factory EntregaSemana.fromJson(Map<String, dynamic> j) {
    // La fecha llega como "2026-11-12T00:00:00": se toma el día tal cual, sin convertir de zona
    final texto = (j['fechaEntrega'] as String?) ?? '';
    final partes = texto.split('T').first.split('-').map(int.tryParse).toList();
    final fecha = partes.length == 3 && !partes.contains(null)
        ? DateTime(partes[0]!, partes[1]!, partes[2]!)
        : soloFecha(DateTime.now());
    return EntregaSemana(
      id: (j['id'] as num).toInt(),
      unidad: j['unidad'] as String? ?? '',
      cliente: j['cliente'] as String?,
      fechaEntrega: fecha,
      notas: j['notas'] as String?,
      entregada: j['entregada'] as bool? ?? false,
      creadoPor: j['creadoPor'] as String?,
      origen: j['origen'] as String? ?? 'manual',
      proyectoId: (j['proyectoId'] as num?)?.toInt(),
      codigo: j['codigo'] as String?,
      oculta: j['oculta'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'unidad': unidad,
        'cliente': cliente,
        'fechaEntrega': '${fechaEntrega.year.toString().padLeft(4, '0')}-'
            '${fechaEntrega.month.toString().padLeft(2, '0')}-${fechaEntrega.day.toString().padLeft(2, '0')}',
        'notas': notas,
        'entregada': entregada,
      };

  EntregaSemana copia() => EntregaSemana(
        id: id,
        unidad: unidad,
        cliente: cliente,
        fechaEntrega: fechaEntrega,
        notas: notas,
        entregada: entregada,
        creadoPor: creadoPor,
        origen: origen,
        proyectoId: proyectoId,
        codigo: codigo,
        oculta: oculta,
      );
}

/// Nota tipo post-it de la coordinación operativa del día (asignación de cuadrillas).
/// Se borra todos los días a las 7 pm.
class NotaCoordinacion {
  int id;
  String cuadrilla;
  String asignacion;
  String color;
  String? creadoPor;
  DateTime creado;

  NotaCoordinacion({
    required this.id,
    required this.cuadrilla,
    required this.asignacion,
    this.color = 'amarillo',
    this.creadoPor,
    required this.creado,
  });

  static const List<String> colores = ['amarillo', 'rosa', 'azul', 'verde', 'naranja'];

  factory NotaCoordinacion.fromJson(Map<String, dynamic> j) => NotaCoordinacion(
        id: (j['id'] as num).toInt(),
        cuadrilla: j['cuadrilla'] as String? ?? '',
        asignacion: j['asignacion'] as String? ?? '',
        color: j['color'] as String? ?? 'amarillo',
        creadoPor: j['creadoPor'] as String?,
        creado: _fecha(j['creado']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {'cuadrilla': cuadrilla, 'asignacion': asignacion, 'color': color};
}

/// Anuncio general escrito por el Admin.
class Anuncio {
  int id;
  String titulo;
  String contenido;
  String? creadoPor;
  DateTime creado;
  DateTime? editado;

  Anuncio({
    required this.id,
    required this.titulo,
    required this.contenido,
    this.creadoPor,
    required this.creado,
    this.editado,
  });

  factory Anuncio.fromJson(Map<String, dynamic> j) => Anuncio(
        id: (j['id'] as num).toInt(),
        titulo: j['titulo'] as String? ?? '',
        contenido: j['contenido'] as String? ?? '',
        creadoPor: j['creadoPor'] as String?,
        creado: _fecha(j['creado']) ?? DateTime.now(),
        editado: _fecha(j['editado']),
      );

  Map<String, dynamic> toJson() => {'titulo': titulo, 'contenido': contenido};
}
