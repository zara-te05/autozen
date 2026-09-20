/// Modelo de dominio para CotizacionModel.
class CotizacionModel {
  final int? idCotizacion;
  final int operacionId;
  final int? trabajadorId;
  final double? manoObraEstimada;
  final double? costoEstimadoPiezas;
  final double? total;
  final String? estadoCotizacion;

  const CotizacionModel({
    this.idCotizacion,
    required this.operacionId,
    this.trabajadorId,
    this.manoObraEstimada,
    this.costoEstimadoPiezas,
    this.total,
    this.estadoCotizacion,
  });

  factory CotizacionModel.fromJson(Map<String, dynamic> json) {
    return CotizacionModel(
      idCotizacion: (json['id_cotizacion'] ?? json['idCotizacion']) != null ? ((json['id_cotizacion'] ?? json['idCotizacion']) as num).toInt() : null,
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      trabajadorId: (json['trabajador_id'] ?? json['trabajadorId']) != null ? ((json['trabajador_id'] ?? json['trabajadorId']) as num).toInt() : null,
      manoObraEstimada: (json['manoObraEstimada'] ?? json['mano_obra_estimada']) != null ? ((json['manoObraEstimada'] ?? json['mano_obra_estimada']) as num).toDouble() : null,
      costoEstimadoPiezas: (json['costoEstimadoPiezas'] ?? json['costo_estimado_piezas']) != null ? ((json['costoEstimadoPiezas'] ?? json['costo_estimado_piezas']) as num).toDouble() : null,
      total: (json['total']) != null ? ((json['total']) as num).toDouble() : null,
      estadoCotizacion: (json['estadoCotizacion'] ?? json['estado_cotizacion']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idCotizacion != null) 'id_cotizacion': idCotizacion,
      'operacion_id': operacionId,
      'trabajador_id': trabajadorId,
      'manoObraEstimada': manoObraEstimada,
      'costoEstimadoPiezas': costoEstimadoPiezas,
      'total': total,
      'estadoCotizacion': estadoCotizacion,
    };
  }

  CotizacionModel copyWith({
    int? idCotizacion,
    int? operacionId,
    int? trabajadorId,
    double? manoObraEstimada,
    double? costoEstimadoPiezas,
    double? total,
    String? estadoCotizacion,
  }) {
    return CotizacionModel(
      idCotizacion: idCotizacion ?? this.idCotizacion,
      operacionId: operacionId ?? this.operacionId,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      manoObraEstimada: manoObraEstimada ?? this.manoObraEstimada,
      costoEstimadoPiezas: costoEstimadoPiezas ?? this.costoEstimadoPiezas,
      total: total ?? this.total,
      estadoCotizacion: estadoCotizacion ?? this.estadoCotizacion,
    );
  }
}
