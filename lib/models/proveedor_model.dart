/// Modelo de dominio para ProveedorModel.
class ProveedorModel {
  final int? idProveedor;
  final String nombreProveedor;
  final String? contacto;
  final int? tiempoEntregaPromedioDias;
  final double? precioPromedio;

  const ProveedorModel({
    this.idProveedor,
    required this.nombreProveedor,
    this.contacto,
    this.tiempoEntregaPromedioDias,
    this.precioPromedio,
  });

  factory ProveedorModel.fromJson(Map<String, dynamic> json) {
    return ProveedorModel(
      idProveedor: (json['id_proveedor'] ?? json['idProveedor']) != null ? ((json['id_proveedor'] ?? json['idProveedor']) as num).toInt() : null,
      nombreProveedor: ((json['nombreProveedor'] ?? json['nombre_proveedor']) ?? '').toString(),
      contacto: (json['contacto']) as String?,
      tiempoEntregaPromedioDias: (json['tiempoEntregaPromedioDias'] ?? json['tiempo_entrega_promedio_dias']) != null ? ((json['tiempoEntregaPromedioDias'] ?? json['tiempo_entrega_promedio_dias']) as num).toInt() : null,
      precioPromedio: (json['precioPromedio'] ?? json['precio_promedio']) != null ? ((json['precioPromedio'] ?? json['precio_promedio']) as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idProveedor != null) 'id_proveedor': idProveedor,
      'nombreProveedor': nombreProveedor,
      'contacto': contacto,
      'tiempoEntregaPromedioDias': tiempoEntregaPromedioDias,
      'precioPromedio': precioPromedio,
    };
  }

  ProveedorModel copyWith({
    int? idProveedor,
    String? nombreProveedor,
    String? contacto,
    int? tiempoEntregaPromedioDias,
    double? precioPromedio,
  }) {
    return ProveedorModel(
      idProveedor: idProveedor ?? this.idProveedor,
      nombreProveedor: nombreProveedor ?? this.nombreProveedor,
      contacto: contacto ?? this.contacto,
      tiempoEntregaPromedioDias: tiempoEntregaPromedioDias ?? this.tiempoEntregaPromedioDias,
      precioPromedio: precioPromedio ?? this.precioPromedio,
    );
  }
}
