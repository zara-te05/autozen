/// Modelo de un proyecto de taller (un camión en reparación) con etapas configurables.
library;

import 'dart:math' as math;

enum TipoProyecto { cliente, aseguradora }

extension TipoProyectoTexto on TipoProyecto {
  String get titulo => this == TipoProyecto.cliente ? 'Proyectos de Clientes' : 'Proyectos de Aseguradora';
  String get singular => this == TipoProyecto.cliente ? 'proyecto de cliente' : 'proyecto de aseguradora';
  String get prefijoId => this == TipoProyecto.cliente ? 'PC' : 'PA';
}

/// Una etapa del proceso de reparación, definida por el propio taller.
class EtapaProyecto {
  String nombre;
  int diasEstimados;

  EtapaProyecto({required this.nombre, required this.diasEstimados});

  EtapaProyecto copia() => EtapaProyecto(nombre: nombre, diasEstimados: diasEstimados);

  factory EtapaProyecto.fromJson(Map<String, dynamic> j) =>
      EtapaProyecto(nombre: j['nombre'] as String? ?? '', diasEstimados: (j['diasEstimados'] as num?)?.toInt() ?? 1);

  Map<String, dynamic> toJson() => {'nombre': nombre, 'diasEstimados': diasEstimados};
}

/// Refacción que se cotizó durante la evaluación de daños.
class RefaccionCotizada {
  final String nombre;
  final int cantidad;

  const RefaccionCotizada({required this.nombre, required this.cantidad});

  factory RefaccionCotizada.fromJson(Map<String, dynamic> j) =>
      RefaccionCotizada(nombre: j['nombre'] as String? ?? '', cantidad: (j['cantidad'] as num?)?.toInt() ?? 1);

  Map<String, dynamic> toJson() => {'nombre': nombre, 'cantidad': cantidad};
}

/// PDF que manda la aseguradora (autorización, póliza, valuación...).
class DocumentoProyecto {
  final int? id;
  final String nombre;

  /// Ruta local (modo demo) o URL "/api/..." del servidor.
  final String ruta;
  final int tamano;
  final DateTime fecha;

  const DocumentoProyecto({this.id, required this.nombre, required this.ruta, required this.tamano, required this.fecha});

  bool get remoto => ruta.startsWith('/api/') || ruta.startsWith('http');

  factory DocumentoProyecto.fromJson(Map<String, dynamic> j) => DocumentoProyecto(
        id: (j['id'] as num?)?.toInt(),
        nombre: j['nombre'] as String? ?? 'documento.pdf',
        ruta: j['url'] as String? ?? '',
        tamano: (j['tamano'] as num?)?.toInt() ?? 0,
        fecha: DateTime.parse(j['fechaSubida'] as String),
      );
}

class ProyectoTaller {
  /// Código que se muestra (PC-001, PA-002).
  final String id;

  /// Id numérico en el backend (en modo demo se genera localmente).
  int? serverId;

  final TipoProyecto tipo;
  String nombreCamion;

  /// Nombre del cliente. Solo aplica a proyectos de cliente.
  String cliente;
  String placa;
  String responsable;

  /// Solo para proyectos de aseguradora (en lugar del cliente).
  String? aseguradora;
  String? numeroSiniestro;

  /// Fecha de entrega prometida a la aseguradora. No es una estimación: si no se cumple, hay multa.
  DateTime? fechaEntregaComprometida;

  final DateTime fechaIngreso;
  List<EtapaProyecto> etapas;

  /// Índice de la etapa en curso. Si es igual a `etapas.length`, todas las etapas están completas.
  int etapaActual;
  bool archivado;

  /// Datos registrados en la Evaluación de Daños (el primer paso de todo proyecto).
  DateTime? fechaEvaluacion;
  String descripcionDanos;
  List<RefaccionCotizada> refaccionesCotizadas;

  /// Fotos: ruta local en el dispositivo (modo demo / antes de subir) o URL "/api/..." del servidor.
  List<String> fotos;

  /// PDFs de la aseguradora.
  List<DocumentoProyecto> documentos;

  ProyectoTaller({
    required this.id,
    required this.tipo,
    required this.nombreCamion,
    required this.cliente,
    required this.placa,
    required this.fechaIngreso,
    required this.etapas,
    this.serverId,
    this.responsable = '',
    this.aseguradora,
    this.numeroSiniestro,
    this.fechaEntregaComprometida,
    this.etapaActual = 0,
    this.archivado = false,
    this.fechaEvaluacion,
    this.descripcionDanos = '',
    List<RefaccionCotizada>? refaccionesCotizadas,
    List<String>? fotos,
    List<DocumentoProyecto>? documentos,
  })  : refaccionesCotizadas = refaccionesCotizadas ?? [],
        fotos = fotos ?? [],
        documentos = documentos ?? [];

  factory ProyectoTaller.fromJson(Map<String, dynamic> j) {
    List<Map<String, dynamic>> lista(String clave) =>
        ((j[clave] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    DateTime? fecha(String clave) => j[clave] == null ? null : DateTime.parse(j[clave] as String);

    return ProyectoTaller(
      id: j['codigo'] as String,
      serverId: (j['id'] as num).toInt(),
      tipo: j['tipo'] == 'Aseguradora' ? TipoProyecto.aseguradora : TipoProyecto.cliente,
      nombreCamion: j['nombreCamion'] as String? ?? '',
      cliente: j['cliente'] as String? ?? '',
      placa: j['placa'] as String? ?? '',
      responsable: j['responsable'] as String? ?? '',
      aseguradora: j['aseguradora'] as String?,
      numeroSiniestro: j['numeroSiniestro'] as String?,
      fechaEntregaComprometida: fecha('fechaEntregaComprometida'),
      fechaIngreso: fecha('fechaIngreso') ?? DateTime.now(),
      etapas: lista('etapas').map(EtapaProyecto.fromJson).toList(),
      etapaActual: (j['etapaActual'] as num?)?.toInt() ?? 0,
      archivado: j['archivado'] as bool? ?? false,
      fechaEvaluacion: fecha('fechaEvaluacion'),
      descripcionDanos: j['descripcionDanos'] as String? ?? '',
      refaccionesCotizadas: lista('refacciones').map(RefaccionCotizada.fromJson).toList(),
      fotos: lista('fotos').map((f) => f['url'] as String).toList(),
      documentos: lista('documentos').map(DocumentoProyecto.fromJson).toList(),
    );
  }

  /// Cuerpo para POST/PUT /api/Proyecto. Al editar, la evaluación no se reenvía (se conserva).
  Map<String, dynamic> toJsonGuardar({required bool incluirEvaluacion}) => {
        'tipo': esAseguradora ? 'Aseguradora' : 'Cliente',
        'nombreCamion': nombreCamion,
        'placa': placa,
        'cliente': esAseguradora ? null : cliente,
        'aseguradora': esAseguradora ? aseguradora : null,
        'numeroSiniestro': esAseguradora ? numeroSiniestro : null,
        'responsable': responsable,
        'fechaIngreso': fechaIngreso.toIso8601String(),
        'fechaEntregaComprometida': fechaEntregaComprometida?.toIso8601String(),
        'etapaActual': etapaActual,
        'etapas': etapas.map((e) => e.toJson()).toList(),
        if (incluirEvaluacion) ...{
          'fechaEvaluacion': fechaEvaluacion?.toIso8601String(),
          'descripcionDanos': descripcionDanos,
          'refacciones': refaccionesCotizadas.map((r) => r.toJson()).toList(),
        },
      };

  /// Copia los datos de otro proyecto (el mismo, recién leído del servidor) sin cambiar de objeto,
  /// para que las pantallas que lo tienen abierto vean los cambios.
  void copiarDe(ProyectoTaller otro) {
    serverId = otro.serverId;
    nombreCamion = otro.nombreCamion;
    cliente = otro.cliente;
    placa = otro.placa;
    responsable = otro.responsable;
    aseguradora = otro.aseguradora;
    numeroSiniestro = otro.numeroSiniestro;
    fechaEntregaComprometida = otro.fechaEntregaComprometida;
    etapas = otro.etapas;
    etapaActual = otro.etapaActual;
    archivado = otro.archivado;
    fechaEvaluacion = otro.fechaEvaluacion;
    descripcionDanos = otro.descripcionDanos;
    refaccionesCotizadas = otro.refaccionesCotizadas;
    fotos = otro.fotos;
    documentos = otro.documentos;
  }

  bool get terminado => etapaActual >= etapas.length;

  String get nombreEtapaActual => terminado ? 'Terminado' : etapas[etapaActual].nombre;

  int get diasTotales => etapas.fold(0, (suma, e) => suma + e.diasEstimados);

  DateTime get fechaEstimadaEntrega => fechaIngreso.add(Duration(days: diasTotales));

  bool get esAseguradora => tipo == TipoProyecto.aseguradora;

  /// Cliente o aseguradora, según el tipo de proyecto.
  String get nombreContraparte => esAseguradora ? (aseguradora ?? '') : cliente;

  /// Aseguradora: la fecha comprometida. Cliente: la estimada a partir de los días de las etapas.
  DateTime get fechaEntrega => esAseguradora && fechaEntregaComprometida != null ? fechaEntregaComprometida! : fechaEstimadaEntrega;

  /// Días que faltan para la entrega (negativo si ya pasó).
  int get diasParaEntrega => diasEntre(DateTime.now(), fechaEntrega);

  bool get entregaVencida => !terminado && diasParaEntrega < 0;

  /// Entrega a aseguradora en 2 días o menos.
  bool get entregaProxima => esAseguradora && !terminado && diasParaEntrega >= 0 && diasParaEntrega <= 2;

  /// El plan de etapas termina después de la fecha prometida a la aseguradora.
  bool get planExcedeEntrega => esAseguradora && fechaEntregaComprometida != null && fechaEstimadaEntrega.isAfter(fechaEntregaComprometida!);

  /// Días calendario entre dos fechas, ignorando la hora.
  static int diasEntre(DateTime desde, DateTime hasta) {
    final a = DateTime(desde.year, desde.month, desde.day);
    final b = DateTime(hasta.year, hasta.month, hasta.day);
    return b.difference(a).inDays;
  }

  /// Reparte [total] días entre las etapas respetando su proporción (mínimo 1 día por etapa).
  static List<EtapaProyecto> repartirDias(List<EtapaProyecto> etapas, int total) {
    final int n = etapas.length;
    if (n == 0) return etapas;
    final int disponibles = math.max(total, n);
    final int pesoTotal = etapas.fold(0, (s, e) => s + e.diasEstimados);
    final dias = [for (final e in etapas) math.max(1, (e.diasEstimados * disponibles / pesoTotal).floor())];

    // Ajusta el redondeo empezando por las etapas más largas
    int diferencia = disponibles - dias.fold(0, (s, d) => s + d);
    final orden = List.generate(n, (i) => i)..sort((a, b) => dias[b].compareTo(dias[a]));
    for (int k = 0; diferencia != 0 && k < n * disponibles; k++) {
      final i = orden[k % n];
      if (diferencia > 0) {
        dias[i]++;
        diferencia--;
      } else if (dias[i] > 1) {
        dias[i]--;
        diferencia++;
      }
    }
    return [for (int i = 0; i < n; i++) EtapaProyecto(nombre: etapas[i].nombre, diasEstimados: dias[i])];
  }

  /// Etapas sugeridas al crear un proyecto nuevo; el usuario puede cambiarlas.
  static List<EtapaProyecto> etapasPorDefecto(TipoProyecto tipo) {
    return [
      EtapaProyecto(nombre: 'Evaluación', diasEstimados: 1),
      if (tipo == TipoProyecto.aseguradora) EtapaProyecto(nombre: 'Autorización de aseguradora', diasEstimados: 3),
      EtapaProyecto(nombre: 'Refacciones', diasEstimados: 3),
      EtapaProyecto(nombre: 'Reparación', diasEstimados: 5),
      EtapaProyecto(nombre: 'Pruebas y entrega', diasEstimados: 1),
    ];
  }
}
