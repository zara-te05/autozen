/// Modelo de dominio para DetalleCotizacionModel.
class DetalleCotizacionModel {
  final int? idDetalleCotizacion;
  final int cotizacionId;
  final int? trabajadorId;
  final String? descripcionTrabajoPieza;
  final double? costoPiezasTomadasAlmacen;
  final int? trabajadoresAsignados;

  const DetalleCotizacionModel({
    this.idDetalleCotizacion,
    required this.cotizacionId,
    this.trabajadorId,
    this.descripcionTrabajoPieza,
    this.costoPiezasTomadasAlmacen,
    this.trabajadoresAsignados,
  });

  factory DetalleCotizacionModel.fromJson(Map<String, dynamic> json) {
    return DetalleCotizacionModel(
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

  DetalleCotizacionModel copyWith({
    int? idDetalleCotizacion,
    int? cotizacionId,
    int? trabajadorId,
    String? descripcionTrabajoPieza,
    double? costoPiezasTomadasAlmacen,
    int? trabajadoresAsignados,
  }) {
    return DetalleCotizacionModel(
      idDetalleCotizacion: idDetalleCotizacion ?? this.idDetalleCotizacion,
      cotizacionId: cotizacionId ?? this.cotizacionId,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      descripcionTrabajoPieza: descripcionTrabajoPieza ?? this.descripcionTrabajoPieza,
      costoPiezasTomadasAlmacen: costoPiezasTomadasAlmacen ?? this.costoPiezasTomadasAlmacen,
      trabajadoresAsignados: trabajadoresAsignados ?? this.trabajadoresAsignados,
    );
  }
}
