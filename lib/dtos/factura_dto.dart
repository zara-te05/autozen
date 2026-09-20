import '../models/factura_model.dart';

/// DTO para transferir datos completos o respuestas de API para FacturaModel.
class FacturaDto {
  final int? idFactura;
  final int operacionId;
  final DateTime fechaEmision;
  final double? montoTotal;
  final String? estadoPago;

  const FacturaDto({
    this.idFactura,
    required this.operacionId,
    required this.fechaEmision,
    this.montoTotal,
    this.estadoPago,
  });

  factory FacturaDto.fromJson(Map<String, dynamic> json) {
    return FacturaDto(
      idFactura: (json['id_factura'] ?? json['idFactura']) != null ? ((json['id_factura'] ?? json['idFactura']) as num).toInt() : null,
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      fechaEmision: DateTime.parse((json['fechaEmision'] ?? json['fecha_emision']).toString()),
      montoTotal: (json['montoTotal'] ?? json['monto_total']) != null ? ((json['montoTotal'] ?? json['monto_total']) as num).toDouble() : null,
      estadoPago: (json['estadoPago'] ?? json['estado_pago']) as String?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (idFactura != null) 'id_factura': idFactura,
      'operacion_id': operacionId,
      'fechaEmision': fechaEmision.toIso8601String(),
      'montoTotal': montoTotal,
      'estadoPago': estadoPago,
    };
  }

  FacturaModel toModel() {
    return FacturaModel(
      idFactura: idFactura,
      operacionId: operacionId,
      fechaEmision: fechaEmision,
      montoTotal: montoTotal,
      estadoPago: estadoPago,
    );
  }

  factory FacturaDto.fromModel(FacturaModel model) {
    return FacturaDto(
      idFactura: model.idFactura,
      operacionId: model.operacionId,
      fechaEmision: model.fechaEmision,
      montoTotal: model.montoTotal,
      estadoPago: model.estadoPago,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateFacturaDto {
  final int operacionId;
  final DateTime fechaEmision;
  final double? montoTotal;
  final String? estadoPago;

  const CreateFacturaDto({
    required this.operacionId,
    required this.fechaEmision,
    this.montoTotal,
    this.estadoPago,
  });

  factory CreateFacturaDto.fromJson(Map<String, dynamic> json) {
    return CreateFacturaDto(
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      fechaEmision: DateTime.parse((json['fechaEmision'] ?? json['fecha_emision']).toString()),
      montoTotal: (json['montoTotal'] ?? json['monto_total']) != null ? ((json['montoTotal'] ?? json['monto_total']) as num).toDouble() : null,
      estadoPago: (json['estadoPago'] ?? json['estado_pago']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operacion_id': operacionId,
      'fechaEmision': fechaEmision.toIso8601String(),
      'montoTotal': montoTotal,
      'estadoPago': estadoPago,
    };
  }
}
