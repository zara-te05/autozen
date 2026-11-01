/// Proveedor de refacciones. Los campos corresponden a la tabla PROVEEDOR del backend.
class Proveedor {
  final String id;
  int? serverId;
  String nombre;
  String contacto;

  /// Dirección que aparece en la orden de compra.
  String direccion;
  int tiempoEntregaDias;
  double? precioPromedio;

  Proveedor({
    required this.id,
    required this.nombre,
    this.contacto = '',
    this.direccion = '',
    this.tiempoEntregaDias = 3,
    this.precioPromedio,
    this.serverId,
  });

  /// Lee el modelo Proveedor del backend (/api/Proveedor).
  factory Proveedor.fromJson(Map<String, dynamic> j) {
    final id = (j['idProveedor'] as num).toInt();
    return Proveedor(
      id: 'PRV-${id.toString().padLeft(3, '0')}',
      serverId: id,
      nombre: j['nombreProveedor'] as String? ?? '',
      contacto: j['contacto'] as String? ?? '',
      direccion: j['direccion'] as String? ?? '',
      tiempoEntregaDias: (j['tiempoEntregaPromedioDias'] as num?)?.toInt() ?? 3,
      precioPromedio: (j['precioPromedio'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nombreProveedor': nombre,
        'contacto': contacto,
        'direccion': direccion,
        'tiempoEntregaPromedioDias': tiempoEntregaDias,
        'precioPromedio': precioPromedio,
      };
}
