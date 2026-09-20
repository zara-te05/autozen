/// Modelo de dominio para FacturaModel.
class FacturaModel {
  final int? idFactura;
  final int operacionId;
  final DateTime fechaEmision;
  final double? montoTotal;
  final String? estadoPago;

  const FacturaModel({
    this.idFactura,
    required this.operacionId,
    required this.fechaEmision,
    this.montoTotal,
    this.estadoPago,
  });

  factory FacturaModel.fromJson(Map<String, dynamic> json) {
    return FacturaModel(
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

  FacturaModel copyWith({
    int? idFactura,
    int? operacionId,
    DateTime? fechaEmision,
    double? montoTotal,
    String? estadoPago,
  }) {
    return FacturaModel(
      idFactura: idFactura ?? this.idFactura,
      operacionId: operacionId ?? this.operacionId,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      montoTotal: montoTotal ?? this.montoTotal,
      estadoPago: estadoPago ?? this.estadoPago,
    );
  }
}
