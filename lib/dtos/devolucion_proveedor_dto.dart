import '../models/devolucion_proveedor_model.dart';

/// DTO para transferir datos completos o respuestas de API para DevolucionProveedorModel.
class DevolucionProveedorDto {
  final int? idDevolucion;
  final int compraId;
  final int proveedorId;
  final String motivo;
  final DateTime fechaDevolucion;
  final String? estadoDevolucion;
  final double? montoReembolso;

  const DevolucionProveedorDto({
    this.idDevolucion,
    required this.compraId,
    required this.proveedorId,
    required this.motivo,
    required this.fechaDevolucion,
    this.estadoDevolucion,
    this.montoReembolso,
  });

  factory DevolucionProveedorDto.fromJson(Map<String, dynamic> json) {
    return DevolucionProveedorDto(
      idDevolucion: (json['id_devolucion'] ?? json['idDevolucion']) != null ? ((json['id_devolucion'] ?? json['idDevolucion']) as num).toInt() : null,
      compraId: ((json['compra_id'] ?? json['compraId']) as num).toInt(),
      proveedorId: ((json['proveedor_id'] ?? json['proveedorId']) as num).toInt(),
      motivo: ((json['motivo']) ?? '').toString(),
      fechaDevolucion: DateTime.parse((json['fechaDevolucion'] ?? json['fecha_devolucion']).toString()),
      estadoDevolucion: (json['estadoDevolucion'] ?? json['estado_devolucion']) as String?,
      montoReembolso: (json['montoReembolso'] ?? json['monto_reembolso']) != null ? ((json['montoReembolso'] ?? json['monto_reembolso']) as num).toDouble() : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      if (idDevolucion != null) 'id_devolucion': idDevolucion,
      'compra_id': compraId,
      'proveedor_id': proveedorId,
      'motivo': motivo,
      'fechaDevolucion': fechaDevolucion.toIso8601String(),
      'estadoDevolucion': estadoDevolucion,
      'montoReembolso': montoReembolso,
    };
  }

  DevolucionProveedorModel toModel() {
    return DevolucionProveedorModel(
      idDevolucion: idDevolucion,
      compraId: compraId,
      proveedorId: proveedorId,
      motivo: motivo,
      fechaDevolucion: fechaDevolucion,
      estadoDevolucion: estadoDevolucion,
      montoReembolso: montoReembolso,
    );
  }

  factory DevolucionProveedorDto.fromModel(DevolucionProveedorModel model) {
    return DevolucionProveedorDto(
      idDevolucion: model.idDevolucion,
      compraId: model.compraId,
      proveedorId: model.proveedorId,
      motivo: model.motivo,
      fechaDevolucion: model.fechaDevolucion,
      estadoDevolucion: model.estadoDevolucion,
      montoReembolso: model.montoReembolso,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateDevolucionProveedorDto {
  final int compraId;
  final int proveedorId;
  final String motivo;
  final DateTime fechaDevolucion;
  final String? estadoDevolucion;
  final double? montoReembolso;

  const CreateDevolucionProveedorDto({
    required this.compraId,
    required this.proveedorId,
    required this.motivo,
    required this.fechaDevolucion,
    this.estadoDevolucion,
    this.montoReembolso,
  });

  factory CreateDevolucionProveedorDto.fromJson(Map<String, dynamic> json) {
    return CreateDevolucionProveedorDto(
      compraId: ((json['compra_id'] ?? json['compraId']) as num).toInt(),
      proveedorId: ((json['proveedor_id'] ?? json['proveedorId']) as num).toInt(),
      motivo: ((json['motivo']) ?? '').toString(),
      fechaDevolucion: DateTime.parse((json['fechaDevolucion'] ?? json['fecha_devolucion']).toString()),
      estadoDevolucion: (json['estadoDevolucion'] ?? json['estado_devolucion']) as String?,
      montoReembolso: (json['montoReembolso'] ?? json['monto_reembolso']) != null ? ((json['montoReembolso'] ?? json['monto_reembolso']) as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compra_id': compraId,
      'proveedor_id': proveedorId,
      'motivo': motivo,
      'fechaDevolucion': fechaDevolucion.toIso8601String(),
      'estadoDevolucion': estadoDevolucion,
      'montoReembolso': montoReembolso,
    };
  }
}
