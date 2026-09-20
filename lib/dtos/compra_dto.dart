import '../models/compra_model.dart';

/// DTO para transferir datos completos o respuestas de API para CompraModel.
class CompraDto {
  final int? idCompra;
  final int solicitudCompraId;
  final int operacionId;
  final String? nombrePiezas;
  final int? cantidadPiezas;
  final double? costoPiezas;

  const CompraDto({
    this.idCompra,
    required this.solicitudCompraId,
    required this.operacionId,
    this.nombrePiezas,
    this.cantidadPiezas,
    this.costoPiezas,
  });

  factory CompraDto.fromJson(Map<String, dynamic> json) {
    return CompraDto(
      idCompra: (json['id_compra'] ?? json['idCompra']) != null ? ((json['id_compra'] ?? json['idCompra']) as num).toInt() : null,
      solicitudCompraId: ((json['solicitud_compra_id'] ?? json['solicitudCompraId']) as num).toInt(),
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      nombrePiezas: (json['nombrePiezas'] ?? json['nombre_piezas']) as String?,
      cantidadPiezas: (json['cantidadPiezas'] ?? json['cantidad_piezas']) != null ? ((json['cantidadPiezas'] ?? json['cantidad_piezas']) as num).toInt() : null,
      costoPiezas: (json['costoPiezas'] ?? json['costo_piezas']) != null ? ((json['costoPiezas'] ?? json['costo_piezas']) as num).toDouble() : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (idCompra != null) 'id_compra': idCompra,
      'solicitud_compra_id': solicitudCompraId,
      'operacion_id': operacionId,
      'nombrePiezas': nombrePiezas,
      'cantidadPiezas': cantidadPiezas,
      'costoPiezas': costoPiezas,
    };
  }

  CompraModel toModel() {
    return CompraModel(
      idCompra: idCompra,
      solicitudCompraId: solicitudCompraId,
      operacionId: operacionId,
      nombrePiezas: nombrePiezas,
      cantidadPiezas: cantidadPiezas,
      costoPiezas: costoPiezas,
    );
  }

  factory CompraDto.fromModel(CompraModel model) {
    return CompraDto(
      idCompra: model.idCompra,
      solicitudCompraId: model.solicitudCompraId,
      operacionId: model.operacionId,
      nombrePiezas: model.nombrePiezas,
      cantidadPiezas: model.cantidadPiezas,
      costoPiezas: model.costoPiezas,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateCompraDto {
  final int solicitudCompraId;
  final int operacionId;
  final String? nombrePiezas;
  final int? cantidadPiezas;
  final double? costoPiezas;

  const CreateCompraDto({
    required this.solicitudCompraId,
    required this.operacionId,
    this.nombrePiezas,
    this.cantidadPiezas,
    this.costoPiezas,
  });

  factory CreateCompraDto.fromJson(Map<String, dynamic> json) {
    return CreateCompraDto(
      solicitudCompraId: ((json['solicitud_compra_id'] ?? json['solicitudCompraId']) as num).toInt(),
      operacionId: ((json['operacion_id'] ?? json['operacionId']) as num).toInt(),
      nombrePiezas: (json['nombrePiezas'] ?? json['nombre_piezas']) as String?,
      cantidadPiezas: (json['cantidadPiezas'] ?? json['cantidad_piezas']) != null ? ((json['cantidadPiezas'] ?? json['cantidad_piezas']) as num).toInt() : null,
      costoPiezas: (json['costoPiezas'] ?? json['costo_piezas']) != null ? ((json['costoPiezas'] ?? json['costo_piezas']) as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'solicitud_compra_id': solicitudCompraId,
      'operacion_id': operacionId,
      'nombrePiezas': nombrePiezas,
      'cantidadPiezas': cantidadPiezas,
      'costoPiezas': costoPiezas,
    };
  }
}
