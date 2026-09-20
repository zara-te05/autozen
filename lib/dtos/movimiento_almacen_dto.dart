import '../models/movimiento_almacen_model.dart';

/// DTO para transferir datos completos o respuestas de API para MovimientoAlmacenModel.
class MovimientoAlmacenDto {
  final int? idMovimiento;
  final int almacenId;
  final int? compraId;
  final int? solicitudAlmacenId;
  final String tipoMovimiento;
  final int cantidad;
  final DateTime fechaMovimiento;

  const MovimientoAlmacenDto({
    this.idMovimiento,
    required this.almacenId,
    this.compraId,
    this.solicitudAlmacenId,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.fechaMovimiento,
  });

  factory MovimientoAlmacenDto.fromJson(Map<String, dynamic> json) {
    return MovimientoAlmacenDto(
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

  MovimientoAlmacenModel toModel() {
    return MovimientoAlmacenModel(
      idMovimiento: idMovimiento,
      almacenId: almacenId,
      compraId: compraId,
      solicitudAlmacenId: solicitudAlmacenId,
      tipoMovimiento: tipoMovimiento,
      cantidad: cantidad,
      fechaMovimiento: fechaMovimiento,
    );
  }

  factory MovimientoAlmacenDto.fromModel(MovimientoAlmacenModel model) {
    return MovimientoAlmacenDto(
      idMovimiento: model.idMovimiento,
      almacenId: model.almacenId,
      compraId: model.compraId,
      solicitudAlmacenId: model.solicitudAlmacenId,
      tipoMovimiento: model.tipoMovimiento,
      cantidad: model.cantidad,
      fechaMovimiento: model.fechaMovimiento,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateMovimientoAlmacenDto {
  final int almacenId;
  final int? compraId;
  final int? solicitudAlmacenId;
  final String tipoMovimiento;
  final int cantidad;
  final DateTime fechaMovimiento;

  const CreateMovimientoAlmacenDto({
    required this.almacenId,
    this.compraId,
    this.solicitudAlmacenId,
    required this.tipoMovimiento,
    required this.cantidad,
    required this.fechaMovimiento,
  });

  factory CreateMovimientoAlmacenDto.fromJson(Map<String, dynamic> json) {
    return CreateMovimientoAlmacenDto(
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
      'almacen_id': almacenId,
      'compra_id': compraId,
      'solicitud_almacen_id': solicitudAlmacenId,
      'tipoMovimiento': tipoMovimiento,
      'cantidad': cantidad,
      'fechaMovimiento': fechaMovimiento.toIso8601String(),
    };
  }
}
