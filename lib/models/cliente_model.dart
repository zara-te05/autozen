/// Modelo de dominio para ClienteModel.
class ClienteModel {
  final int? idCliente;
  final String nombre;
  final String apellido;
  final String numTelefono;
  final String? metodoContactoAlternativo;
  final String lugarProcedencia;

  const ClienteModel({
    this.idCliente,
    required this.nombre,
    required this.apellido,
    required this.numTelefono,
    this.metodoContactoAlternativo,
    required this.lugarProcedencia,
  });

  factory ClienteModel.fromJson(Map<String, dynamic> json) {
    return ClienteModel(
      idCliente: (json['id_cliente'] ?? json['idCliente']) != null ? ((json['id_cliente'] ?? json['idCliente']) as num).toInt() : null,
      nombre: ((json['nombre']) ?? '').toString(),
      apellido: ((json['apellido']) ?? '').toString(),
      numTelefono: ((json['numTelefono'] ?? json['num_telefono']) ?? '').toString(),
      metodoContactoAlternativo: (json['metodoContactoAlternativo'] ?? json['metodo_contacto_alternativo']) as String?,
      lugarProcedencia: ((json['lugarProcedencia'] ?? json['lugar_procedencia']) ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idCliente != null) 'id_cliente': idCliente,
      'nombre': nombre,
      'apellido': apellido,
      'numTelefono': numTelefono,
      'metodoContactoAlternativo': metodoContactoAlternativo,
      'lugarProcedencia': lugarProcedencia,
    };
  }

  ClienteModel copyWith({
    int? idCliente,
    String? nombre,
    String? apellido,
    String? numTelefono,
    String? metodoContactoAlternativo,
    String? lugarProcedencia,
  }) {
    return ClienteModel(
      idCliente: idCliente ?? this.idCliente,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      numTelefono: numTelefono ?? this.numTelefono,
      metodoContactoAlternativo: metodoContactoAlternativo ?? this.metodoContactoAlternativo,
      lugarProcedencia: lugarProcedencia ?? this.lugarProcedencia,
    );
  }
}
