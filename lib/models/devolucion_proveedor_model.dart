/// Modelo de dominio para DevolucionProveedorModel.
class DevolucionProveedorModel {
  final int? idDevolucion;
  final int compraId;
  final int proveedorId;
  final String motivo;
  final DateTime fechaDevolucion;
  final String? estadoDevolucion;
  final double? montoReembolso;

  const DevolucionProveedorModel({
    this.idDevolucion,
    required this.compraId,
    required this.proveedorId,
    required this.motivo,
    required this.fechaDevolucion,
    this.estadoDevolucion,
    this.montoReembolso,
  });

  factory DevolucionProveedorModel.fromJson(Map<String, dynamic> json) {
    return DevolucionProveedorModel(
      idDevolucion: (json['id_devolucion'] ?? json['idDevolucion']) != null ? ((json['id_devolucion'] ?? json['idDevolucion']) as num).toInt() : null,
      compraId: ((json['compra_id'] ?? json['compraId']) as num).toInt(),
      proveedorId: ((json['proveedor_id'] ?? json['proveedorId']) as num).toInt(),
      motivo: ((json['motivo']) ?? '').toString(),
      fechaDevolucion: DateTime.parse((json['fechaDevolucion'] ?? json['fecha_devolucion']).toString()),
      estadoDevolucion: (json['estadoDevolucion'] ?? json['estado_devolucion']) as String?,
      montoReembolso: (json['montoReembolso'] ?? json['monto_reembolso']) != null ? ((json['montoReembolso'] ?? json['monto_reembolso']) as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idDevolucion != null) 'id_devolucion': idDevolucion,
      'compra_id': compraId,
      'proveedor_id': proveedorId,
      'motivo': motivo,
      'fechaDevolucion': fechaDevolucion.toIso8601String(),
      'estadoDevolucion': estadoDevolucion,
      'montoReembolso': montoReembolso,
    };
  }

  DevolucionProveedorModel copyWith({
    int? idDevolucion,
    int? compraId,
    int? proveedorId,
    String? motivo,
    DateTime? fechaDevolucion,
    String? estadoDevolucion,
    double? montoReembolso,
  }) {
    return DevolucionProveedorModel(
      idDevolucion: idDevolucion ?? this.idDevolucion,
      compraId: compraId ?? this.compraId,
      proveedorId: proveedorId ?? this.proveedorId,
      motivo: motivo ?? this.motivo,
      fechaDevolucion: fechaDevolucion ?? this.fechaDevolucion,
      estadoDevolucion: estadoDevolucion ?? this.estadoDevolucion,
      montoReembolso: montoReembolso ?? this.montoReembolso,
    );
  }
}
