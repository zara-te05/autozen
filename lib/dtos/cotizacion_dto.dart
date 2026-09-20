import '../models/cotizacion_model.dart';

/// DTO para transferir datos completos o respuestas de API para CotizacionModel.
class CotizacionDto {
  final int? idCotizacion;
  final int operacionId;
  final int? trabajadorId;
  final double? manoObraEstimada;
  final double? costoEstimadoPiezas;
  final double? total;
  final String? estadoCotizacion;

  const CotizacionDto({
    this.idCotizacion,
    required this.operacionId,
    this.trabajadorId,
    this.manoObraEstimada,
    this.costoEstimadoPiezas,
    this.total,
    this.estadoCotizacion,
  });

  factory CotizacionDto.fromJson(Map<String, dynamic> json) {
    return CotizacionDto(
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

  CotizacionModel toModel() {
    return CotizacionModel(
      idCotizacion: idCotizacion,
      operacionId: operacionId,
      trabajadorId: trabajadorId,
      manoObraEstimada: manoObraEstimada,
      costoEstimadoPiezas: costoEstimadoPiezas,
      total: total,
      estadoCotizacion: estadoCotizacion,
    );
  }

  factory CotizacionDto.fromModel(CotizacionModel model) {
    return CotizacionDto(
      idCotizacion: model.idCotizacion,
      operacionId: model.operacionId,
      trabajadorId: model.trabajadorId,
      manoObraEstimada: model.manoObraEstimada,
      costoEstimadoPiezas: model.costoEstimadoPiezas,
      total: model.total,
      estadoCotizacion: model.estadoCotizacion,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateCotizacionDto {
  final int operacionId;
  final int? trabajadorId;
  final double? manoObraEstimada;
  final double? costoEstimadoPiezas;
  final double? total;
  final String? estadoCotizacion;

  const CreateCotizacionDto({
    required this.operacionId,
    this.trabajadorId,
    this.manoObraEstimada,
    this.costoEstimadoPiezas,
    this.total,
    this.estadoCotizacion,
  });

  factory CreateCotizacionDto.fromJson(Map<String, dynamic> json) {
    return CreateCotizacionDto(
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
      'operacion_id': operacionId,
      'trabajador_id': trabajadorId,
      'manoObraEstimada': manoObraEstimada,
      'costoEstimadoPiezas': costoEstimadoPiezas,
      'total': total,
      'estadoCotizacion': estadoCotizacion,
    };
  }
}
