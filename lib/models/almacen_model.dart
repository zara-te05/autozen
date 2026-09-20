/// Modelo de dominio para AlmacenModel.
class AlmacenModel {
  final int? idAlmacen;
  final String nombrePieza;
  final int? cantidadStock;
  final double? costoPiezas;

  const AlmacenModel({
    this.idAlmacen,
    required this.nombrePieza,
    this.cantidadStock,
    this.costoPiezas,
  });

  factory AlmacenModel.fromJson(Map<String, dynamic> json) {
    return AlmacenModel(
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

  AlmacenModel copyWith({
    int? idAlmacen,
    String? nombrePieza,
    int? cantidadStock,
    double? costoPiezas,
  }) {
    return AlmacenModel(
      idAlmacen: idAlmacen ?? this.idAlmacen,
      nombrePieza: nombrePieza ?? this.nombrePieza,
      cantidadStock: cantidadStock ?? this.cantidadStock,
      costoPiezas: costoPiezas ?? this.costoPiezas,
    );
  }
}
