import 'dart:convert';
import 'dart:typed_data';

/// Renglón de la hoja "Entrega de placas a almacén": lo que se guarda de un camión que llega.
class RegistroResguardo {
  final int id;
  String empresa;
  String tipoUnidad;
  String numeroUnidad;

  /// Qué se entrega al almacén (placas, placa logotipo, válvula de descarga...).
  String objetos;
  DateTime fechaIngreso;

  /// Operador que entrega y su firma (PNG).
  String operador;
  Uint8List? firma;

  /// Salida de almacén: cuándo y a quién se regresó.
  DateTime? fechaSalida;
  String? entregadoA;
  String? notasSalida;

  RegistroResguardo({
    required this.id,
    required this.empresa,
    required this.tipoUnidad,
    required this.numeroUnidad,
    required this.objetos,
    required this.fechaIngreso,
    required this.operador,
    this.firma,
    this.fechaSalida,
    this.entregadoA,
    this.notasSalida,
  });

  bool get enAlmacen => fechaSalida == null;
  int get diasEnAlmacen => (fechaSalida ?? DateTime.now()).difference(fechaIngreso).inDays;

  factory RegistroResguardo.fromJson(Map<String, dynamic> j) => RegistroResguardo(
        id: (j['id'] as num).toInt(),
        empresa: j['empresa'] as String? ?? '',
        tipoUnidad: j['tipoUnidad'] as String? ?? '',
        numeroUnidad: j['numeroUnidad'] as String? ?? '',
        objetos: j['objetos'] as String? ?? '',
        fechaIngreso: DateTime.parse(j['fechaIngreso'] as String),
        operador: j['operador'] as String? ?? '',
        firma: (j['firma'] as String?)?.isNotEmpty == true ? base64Decode(j['firma'] as String) : null,
        fechaSalida: j['fechaSalida'] == null ? null : DateTime.parse(j['fechaSalida'] as String),
        entregadoA: j['entregadoA'] as String?,
        notasSalida: j['notasSalida'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'empresa': empresa,
        'tipoUnidad': tipoUnidad,
        'numeroUnidad': numeroUnidad,
        'objetos': objetos,
        'fechaIngreso': fechaIngreso.toIso8601String(),
        'operador': operador,
        'firma': firma == null ? null : base64Encode(firma!),
      };
}

const List<String> tiposUnidadSugeridos = ['Tanque', 'Caja', 'Tractocamión (CT)', 'Pipa', 'Torton', 'Rabón', 'Camioneta', 'Tolva'];
const List<String> objetosSugeridos = ['Placas', 'Placa logotipo', 'Válvula de descarga', 'Plafones', 'Tarjeta de circulación', 'Llaves'];
