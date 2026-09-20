/// Modelo de dominio para CompraModel.
class CompraModel {
  final int? idCompra;
  final int solicitudCompraId;
  final int operacionId;
  final String? nombrePiezas;
  final int? cantidadPiezas;
  final double? costoPiezas;

  const CompraModel({
    this.idCompra,
    required this.solicitudCompraId,
    required this.operacionId,
    this.nombrePiezas,
    this.cantidadPiezas,
    this.costoPiezas,
  });

  factory CompraModel.fromJson(Map<String, dynamic> json) {
    return CompraModel(
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

  CompraModel copyWith({
    int? idCompra,
    int? solicitudCompraId,
    int? operacionId,
    String? nombrePiezas,
    int? cantidadPiezas,
    double? costoPiezas,
  }) {
    return CompraModel(
      idCompra: idCompra ?? this.idCompra,
      solicitudCompraId: solicitudCompraId ?? this.solicitudCompraId,
      operacionId: operacionId ?? this.operacionId,
      nombrePiezas: nombrePiezas ?? this.nombrePiezas,
      cantidadPiezas: cantidadPiezas ?? this.cantidadPiezas,
      costoPiezas: costoPiezas ?? this.costoPiezas,
    );
  }
}
