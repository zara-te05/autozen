import '../models/almacen_model.dart';

/// DTO para transferir datos completos o respuestas de API para AlmacenModel.
class AlmacenDto {
  final int? idAlmacen;
  final String nombrePieza;
  final int? cantidadStock;
  final double? costoPiezas;

  const AlmacenDto({
    this.idAlmacen,
    required this.nombrePieza,
    this.cantidadStock,
    this.costoPiezas,
  });

  factory AlmacenDto.fromJson(Map<String, dynamic> json) {
    return AlmacenDto(
      idAlmacen: (json['id_almacen'] ?? json['idAlmacen']) != null ? ((json['id_almacen'] ?? json['idAlmacen']) as num).toInt() : null,
      nombrePieza: ((json['nombrePieza'] ?? json['nombre_pieza']) ?? '').toString(),
      cantidadStock: (json['cantidadStock'] ?? json['cantidad_stock']) != null ? ((json['cantidadStock'] ?? json['cantidad_stock']) as num).toInt() : null,
      costoPiezas: (json['costoPiezas'] ?? json['costo_piezas']) != null ? ((json['costoPiezas'] ?? json['costo_piezas']) as num).toDouble() : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (idAlmacen != null) 'id_almacen': idAlmacen,
      'nombrePieza': nombrePieza,
      'cantidadStock': cantidadStock,
      'costoPiezas': costoPiezas,
    };
  }

  AlmacenModel toModel() {
    return AlmacenModel(
      idAlmacen: idAlmacen,
      nombrePieza: nombrePieza,
      cantidadStock: cantidadStock,
      costoPiezas: costoPiezas,
    );
  }

  factory AlmacenDto.fromModel(AlmacenModel model) {
    return AlmacenDto(
      idAlmacen: model.idAlmacen,
      nombrePieza: model.nombrePieza,
      cantidadStock: model.cantidadStock,
      costoPiezas: model.costoPiezas,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateAlmacenDto {
  final String nombrePieza;
  final int? cantidadStock;
  final double? costoPiezas;

  const CreateAlmacenDto({
    required this.nombrePieza,
    this.cantidadStock,
    this.costoPiezas,
  });

  factory CreateAlmacenDto.fromJson(Map<String, dynamic> json) {
    return CreateAlmacenDto(
      nombrePieza: ((json['nombrePieza'] ?? json['nombre_pieza']) ?? '').toString(),
      cantidadStock: (json['cantidadStock'] ?? json['cantidad_stock']) != null ? ((json['cantidadStock'] ?? json['cantidad_stock']) as num).toInt() : null,
      costoPiezas: (json['costoPiezas'] ?? json['costo_piezas']) != null ? ((json['costoPiezas'] ?? json['costo_piezas']) as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombrePieza': nombrePieza,
      'cantidadStock': cantidadStock,
      'costoPiezas': costoPiezas,
    };
  }
}
