import '../models/detalle_cotizacion_model.dart';

/// DTO para transferir datos completos o respuestas de API para DetalleCotizacionModel.
class DetalleCotizacionDto {
  final int? idDetalleCotizacion;
  final int cotizacionId;
  final int? trabajadorId;
  final String? descripcionTrabajoPieza;
  final double? costoPiezasTomadasAlmacen;
  final int? trabajadoresAsignados;

  const DetalleCotizacionDto({
    this.idDetalleCotizacion,
    required this.cotizacionId,
    this.trabajadorId,
    this.descripcionTrabajoPieza,
    this.costoPiezasTomadasAlmacen,
    this.trabajadoresAsignados,
  });

  factory DetalleCotizacionDto.fromJson(Map<String, dynamic> json) {
    return DetalleCotizacionDto(
      idDetalleCotizacion: (json['id_detalle_cotizacion'] ?? json['idDetalleCotizacion']) != null ? ((json['id_detalle_cotizacion'] ?? json['idDetalleCotizacion']) as num).toInt() : null,
      cotizacionId: ((json['cotizacion_id'] ?? json['cotizacionId']) as num).toInt(),
      trabajadorId: (json['trabajador_id'] ?? json['trabajadorId']) != null ? ((json['trabajador_id'] ?? json['trabajadorId']) as num).toInt() : null,
      descripcionTrabajoPieza: (json['descripcionTrabajo_Pieza'] ?? json['descripcion_trabajo_pieza'] ?? json['descripcionTrabajoPieza']) as String?,
      costoPiezasTomadasAlmacen: (json['costoPiezasTomadasAlmacen'] ?? json['costo_piezas_tomadas_almacen']) != null ? ((json['costoPiezasTomadasAlmacen'] ?? json['costo_piezas_tomadas_almacen']) as num).toDouble() : null,
      trabajadoresAsignados: (json['trabajadoresAsignados'] ?? json['trabajadores_asignados']) != null ? ((json['trabajadoresAsignados'] ?? json['trabajadores_asignados']) as num).toInt() : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (idDetalleCotizacion != null) 'id_detalle_cotizacion': idDetalleCotizacion,
      'cotizacion_id': cotizacionId,
      'trabajador_id': trabajadorId,
      'descripcionTrabajo_Pieza': descripcionTrabajoPieza,
      'costoPiezasTomadasAlmacen': costoPiezasTomadasAlmacen,
      'trabajadoresAsignados': trabajadoresAsignados,
    };
  }

  DetalleCotizacionModel toModel() {
    return DetalleCotizacionModel(
      idDetalleCotizacion: idDetalleCotizacion,
      cotizacionId: cotizacionId,
      trabajadorId: trabajadorId,
      descripcionTrabajoPieza: descripcionTrabajoPieza,
      costoPiezasTomadasAlmacen: costoPiezasTomadasAlmacen,
      trabajadoresAsignados: trabajadoresAsignados,
    );
  }

  factory DetalleCotizacionDto.fromModel(DetalleCotizacionModel model) {
    return DetalleCotizacionDto(
      idDetalleCotizacion: model.idDetalleCotizacion,
      cotizacionId: model.cotizacionId,
      trabajadorId: model.trabajadorId,
      descripcionTrabajoPieza: model.descripcionTrabajoPieza,
      costoPiezasTomadasAlmacen: model.costoPiezasTomadasAlmacen,
      trabajadoresAsignados: model.trabajadoresAsignados,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateDetalleCotizacionDto {
  final int cotizacionId;
  final int? trabajadorId;
  final String? descripcionTrabajoPieza;
  final double? costoPiezasTomadasAlmacen;
  final int? trabajadoresAsignados;

  const CreateDetalleCotizacionDto({
    required this.cotizacionId,
    this.trabajadorId,
    this.descripcionTrabajoPieza,
    this.costoPiezasTomadasAlmacen,
    this.trabajadoresAsignados,
  });

  factory CreateDetalleCotizacionDto.fromJson(Map<String, dynamic> json) {
    return CreateDetalleCotizacionDto(
      cotizacionId: ((json['cotizacion_id'] ?? json['cotizacionId']) as num).toInt(),
      trabajadorId: (json['trabajador_id'] ?? json['trabajadorId']) != null ? ((json['trabajador_id'] ?? json['trabajadorId']) as num).toInt() : null,
      descripcionTrabajoPieza: (json['descripcionTrabajo_Pieza'] ?? json['descripcion_trabajo_pieza'] ?? json['descripcionTrabajoPieza']) as String?,
      costoPiezasTomadasAlmacen: (json['costoPiezasTomadasAlmacen'] ?? json['costo_piezas_tomadas_almacen']) != null ? ((json['costoPiezasTomadasAlmacen'] ?? json['costo_piezas_tomadas_almacen']) as num).toDouble() : null,
      trabajadoresAsignados: (json['trabajadoresAsignados'] ?? json['trabajadores_asignados']) != null ? ((json['trabajadoresAsignados'] ?? json['trabajadores_asignados']) as num).toInt() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cotizacion_id': cotizacionId,
      'trabajador_id': trabajadorId,
      'descripcionTrabajo_Pieza': descripcionTrabajoPieza,
      'costoPiezasTomadasAlmacen': costoPiezasTomadasAlmacen,
      'trabajadoresAsignados': trabajadoresAsignados,
    };
  }
}
