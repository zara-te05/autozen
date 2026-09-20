/// Modelo de dominio para MovimientoAlmacenModel.
class MovimientoAlmacenModel {
  final int? idMovimiento;
  final int almacenId;
  final int? compraId;
  final int? solicitudAlmacenId;
  final String tipoMovimiento;
  final int cantidad;
  final DateTime fechaMovimiento;

  const MovimientoAlmacenModel({
    this.idMovimiento,
    required this.almacenId,
    this.compraId,
    this.solicitudAlmacenId,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.fechaMovimiento,
  });

  factory MovimientoAlmacenModel.fromJson(Map<String, dynamic> json) {
    return MovimientoAlmacenModel(
      idMovimiento: (json['id_movimiento'] ?? json['idMovimiento']) != null ? ((json['id_movimiento'] ?? json['idMovimiento']) as num).toInt() : null,
      almacenId: ((json['almacen_id'] ?? json['almacenId']) as num).toInt(),
      compraId: (json['compra_id'] ?? json['compraId']) != null ? ((json['compra_id'] ?? json['compraId']) as num).toInt() : null,
      solicitudAlmacenId: (json['solicitud_almacen_id'] ?? json['solicitudAlmacenId']) != null ? ((json['solicitud_almacen_id'] ?? json['solicitudAlmacenId']) as num).toInt() : null,
      tipoMovimiento: ((json['tipoMovimiento'] ?? json['tipo_movimiento']) ?? '').toString(),
      cantidad: ((json['cantidad']) as num).toInt(),
      fechaMovimiento: DateTime.parse((json['fechaMovimiento'] ?? json['fecha_movimiento']).toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idMovimiento != null) 'id_movimiento': idMovimiento,
      'almacen_id': almacenId,
      'compra_id': compraId,
      'solicitud_almacen_id': solicitudAlmacenId,
      'tipoMovimiento': tipoMovimiento,
      'cantidad': cantidad,
      'fechaMovimiento': fechaMovimiento.toIso8601String(),
    };
  }

  MovimientoAlmacenModel copyWith({
    int? idMovimiento,
    int? almacenId,
    int? compraId,
    int? solicitudAlmacenId,
    String? tipoMovimiento,
    int? cantidad,
    DateTime? fechaMovimiento,
  }) {
    return MovimientoAlmacenModel(
      idMovimiento: idMovimiento ?? this.idMovimiento,
      almacenId: almacenId ?? this.almacenId,
      compraId: compraId ?? this.compraId,
      solicitudAlmacenId: solicitudAlmacenId ?? this.solicitudAlmacenId,
      tipoMovimiento: tipoMovimiento ?? this.tipoMovimiento,
      cantidad: cantidad ?? this.cantidad,
      fechaMovimiento: fechaMovimiento ?? this.fechaMovimiento,
    );
  }
}
