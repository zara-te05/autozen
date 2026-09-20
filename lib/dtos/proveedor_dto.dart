import '../models/proveedor_model.dart';

/// DTO para transferir datos completos o respuestas de API para ProveedorModel.
class ProveedorDto {
  final int? idProveedor;
  final String nombreProveedor;
  final String? contacto;
  final int? tiempoEntregaPromedioDias;
  final double? precioPromedio;

  const ProveedorDto({
    this.idProveedor,
    required this.nombreProveedor,
    this.contacto,
    this.tiempoEntregaPromedioDias,
    this.precioPromedio,
  });

  factory ProveedorDto.fromJson(Map<String, dynamic> json) {
    return ProveedorDto(
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

  ProveedorModel toModel() {
    return ProveedorModel(
      idProveedor: idProveedor,
      nombreProveedor: nombreProveedor,
      contacto: contacto,
      tiempoEntregaPromedioDias: tiempoEntregaPromedioDias,
      precioPromedio: precioPromedio,
    );
  }

  factory ProveedorDto.fromModel(ProveedorModel model) {
    return ProveedorDto(
      idProveedor: model.idProveedor,
      nombreProveedor: model.nombreProveedor,
      contacto: model.contacto,
      tiempoEntregaPromedioDias: model.tiempoEntregaPromedioDias,
      precioPromedio: model.precioPromedio,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateProveedorDto {
  final String nombreProveedor;
  final String? contacto;
  final int? tiempoEntregaPromedioDias;
  final double? precioPromedio;

  const CreateProveedorDto({
    required this.nombreProveedor,
    this.contacto,
    this.tiempoEntregaPromedioDias,
    this.precioPromedio,
  });

  factory CreateProveedorDto.fromJson(Map<String, dynamic> json) {
    return CreateProveedorDto(
      nombreProveedor: ((json['nombreProveedor'] ?? json['nombre_proveedor']) ?? '').toString(),
      contacto: (json['contacto']) as String?,
      tiempoEntregaPromedioDias: (json['tiempoEntregaPromedioDias'] ?? json['tiempo_entrega_promedio_dias']) != null ? ((json['tiempoEntregaPromedioDias'] ?? json['tiempo_entrega_promedio_dias']) as num).toInt() : null,
      precioPromedio: (json['precioPromedio'] ?? json['precio_promedio']) != null ? ((json['precioPromedio'] ?? json['precio_promedio']) as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombreProveedor': nombreProveedor,
      'contacto': contacto,
      'tiempoEntregaPromedioDias': tiempoEntregaPromedioDias,
      'precioPromedio': precioPromedio,
    };
  }
}
