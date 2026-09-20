import '../models/cliente_model.dart';

/// DTO para transferir datos completos o respuestas de API para ClienteModel.
class ClienteDto {
  final int? idCliente;
  final String nombre;
  final String apellido;
  final String numTelefono;
  final String? metodoContactoAlternativo;
  final String lugarProcedencia;

  const ClienteDto({
    this.idCliente,
    required this.nombre,
    required this.apellido,
    required this.numTelefono,
    this.metodoContactoAlternativo,
    required this.lugarProcedencia,
  });

  factory ClienteDto.fromJson(Map<String, dynamic> json) {
    return ClienteDto(
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

  ClienteModel toModel() {
    return ClienteModel(
      idCliente: idCliente,
      nombre: nombre,
      apellido: apellido,
      numTelefono: numTelefono,
      metodoContactoAlternativo: metodoContactoAlternativo,
      lugarProcedencia: lugarProcedencia,
    );
  }

  factory ClienteDto.fromModel(ClienteModel model) {
    return ClienteDto(
      idCliente: model.idCliente,
      nombre: model.nombre,
      apellido: model.apellido,
      numTelefono: model.numTelefono,
      metodoContactoAlternativo: model.metodoContactoAlternativo,
      lugarProcedencia: model.lugarProcedencia,
    );
  }
}

/// DTO utilizado para enviar datos de creación a la API / base de datos.
class CreateClienteDto {
  final String nombre;
  final String apellido;
  final String numTelefono;
  final String? metodoContactoAlternativo;
  final String lugarProcedencia;

  const CreateClienteDto({
    required this.nombre,
    required this.apellido,
    required this.numTelefono,
    this.metodoContactoAlternativo,
    required this.lugarProcedencia,
  });

  factory CreateClienteDto.fromJson(Map<String, dynamic> json) {
    return CreateClienteDto(
      nombre: ((json['nombre']) ?? '').toString(),
      apellido: ((json['apellido']) ?? '').toString(),
      numTelefono: ((json['numTelefono'] ?? json['num_telefono']) ?? '').toString(),
      metodoContactoAlternativo: (json['metodoContactoAlternativo'] ?? json['metodo_contacto_alternativo']) as String?,
      lugarProcedencia: ((json['lugarProcedencia'] ?? json['lugar_procedencia']) ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'numTelefono': numTelefono,
      'metodoContactoAlternativo': metodoContactoAlternativo,
      'lugarProcedencia': lugarProcedencia,
    };
  }
}
