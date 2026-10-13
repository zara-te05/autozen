using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Dapper;

namespace Autozen.Api.Services;

public class ProyectoService
{
    private readonly DapperContext _context;
    private readonly IClienteRepository _clienteRepo;
    private readonly ICamionRepository _camionRepo;
    private readonly IOperacionRepository _operacionRepo;

    public ProyectoService(
        DapperContext context,
        IClienteRepository clienteRepo,
        ICamionRepository camionRepo,
        IOperacionRepository operacionRepo)
    {
        _context = context;
        _clienteRepo = clienteRepo;
        _camionRepo = camionRepo;
        _operacionRepo = operacionRepo;
    }

    /// <summary>
    /// Consulta y lista todos los proyectos combinando datos del Camión, Cliente y Avance de Operación.
    /// </summary>
    public async Task<IEnumerable<ProyectoDetalleResponseDto>> GetAllAsync()
    {
        const string query = @"
            SELECT 
                o.""id_operacion"" AS ""IdProyecto"",
                c.""id_camion"" AS ""IdCamion"",
                c.""placas"" AS ""Placas"",
                c.""marca"" AS ""Marca"",
                c.""modelo"" AS ""Modelo"",
                c.""fechaEntrada"" AS ""FechaEntrada"",
                c.""tiempoEsperado"" AS ""TiempoEsperado"",
                cl.""id_cliente"" AS ""IdCliente"",
                cl.""nombre"" AS ""NombreCliente"",
                cl.""apellido"" AS ""ApellidoCliente"",
                cl.""numTelefono"" AS ""TelefonoCliente"",
                cl.""lugarProcedencia"" AS ""LugarProcedencia"",
                o.""usuario_id"" AS ""UsuarioIdResponsable"",
                u.""nombre"" AS ""NombreResponsable"",
                o.""fechaInicio"" AS ""FechaInicio"",
                o.""fechaEstimadaFinalizacion"" AS ""FechaEstimadaFinalizacion"",
                o.""estadoOperacion"" AS ""EstadoOperacion""
            FROM OPERACIONES o
            INNER JOIN CAMION c ON o.""camion_id"" = c.""id_camion""
            INNER JOIN CLIENTE cl ON c.""cliente_id"" = cl.""id_cliente""
            LEFT JOIN USUARIO u ON o.""usuario_id"" = u.""id_usuario""
            ORDER BY o.""id_operacion"" DESC;";

        using var connection = _context.CreateConnection();
        var lista = await connection.QueryAsync<dynamic>(query);

        return lista.Select(item =>
        {
            string estado = (string)(item.EstadoOperacion ?? "Iniciado");
            bool solicitaBaja = estado.StartsWith("Solicitud_Baja", StringComparison.OrdinalIgnoreCase);
            string? motivo = solicitaBaja && estado.Contains(':') 
                ? estado.Substring(estado.IndexOf(':') + 1).Trim() 
                : null;

            return new ProyectoDetalleResponseDto
            {
                IdProyecto = (int)item.IdProyecto,
                IdCamion = (int)item.IdCamion,
                Placas = (string)item.Placas,
                Marca = (string?)item.Marca,
                Modelo = (string?)item.Modelo,
                FechaEntrada = (DateTime)item.FechaEntrada,
                TiempoEsperado = (DateTime)item.TiempoEsperado,
                DanoEstimado = null, // Compatible con BD actual
                IdCliente = (int)item.IdCliente,
                NombreCliente = (string)item.NombreCliente,
                ApellidoCliente = (string?)item.ApellidoCliente,
                TelefonoCliente = (string?)item.TelefonoCliente,
                LugarProcedencia = (string?)item.LugarProcedencia,
                UsuarioIdResponsable = (int?)item.UsuarioIdResponsable,
                NombreResponsable = (string?)item.NombreResponsable,
                FechaInicio = (DateTime)item.FechaInicio,
                FechaEstimadaFinalizacion = (DateTime)item.FechaEstimadaFinalizacion,
                EstadoOperacion = estado,
                SolicitaEliminacion = solicitaBaja,
                MotivoEliminacion = motivo
            };
        });
    }

    /// <summary>
    /// Obtiene el detalle técnico completo de un proyecto por su identificador.
    /// </summary>
    public async Task<ProyectoDetalleResponseDto?> GetByIdAsync(int idProyecto)
    {
        const string query = @"
            SELECT 
                o.""id_operacion"" AS ""IdProyecto"",
                c.""id_camion"" AS ""IdCamion"",
                c.""placas"" AS ""Placas"",
                c.""marca"" AS ""Marca"",
                c.""modelo"" AS ""Modelo"",
                c.""fechaEntrada"" AS ""FechaEntrada"",
                c.""tiempoEsperado"" AS ""TiempoEsperado"",
                cl.""id_cliente"" AS ""IdCliente"",
                cl.""nombre"" AS ""NombreCliente"",
                cl.""apellido"" AS ""ApellidoCliente"",
                cl.""numTelefono"" AS ""TelefonoCliente"",
                cl.""lugarProcedencia"" AS ""LugarProcedencia"",
                o.""usuario_id"" AS ""UsuarioIdResponsable"",
                u.""nombre"" AS ""NombreResponsable"",
                o.""fechaInicio"" AS ""FechaInicio"",
                o.""fechaEstimadaFinalizacion"" AS ""FechaEstimadaFinalizacion"",
                o.""estadoOperacion"" AS ""EstadoOperacion""
            FROM OPERACIONES o
            INNER JOIN CAMION c ON o.""camion_id"" = c.""id_camion""
            INNER JOIN CLIENTE cl ON c.""cliente_id"" = cl.""id_cliente""
            LEFT JOIN USUARIO u ON o.""usuario_id"" = u.""id_usuario""
            WHERE o.""id_operacion"" = @Id;";

        using var connection = _context.CreateConnection();
        var item = await connection.QueryFirstOrDefaultAsync<dynamic>(query, new { Id = idProyecto });

        if (item == null)
            return null;

        string estado = (string)(item.EstadoOperacion ?? "Iniciado");
        bool solicitaBaja = estado.StartsWith("Solicitud_Baja", StringComparison.OrdinalIgnoreCase);
        string? motivo = solicitaBaja && estado.Contains(':') 
            ? estado.Substring(estado.IndexOf(':') + 1).Trim() 
            : null;

        return new ProyectoDetalleResponseDto
        {
            IdProyecto = (int)item.IdProyecto,
            IdCamion = (int)item.IdCamion,
            Placas = (string)item.Placas,
            Marca = (string?)item.Marca,
            Modelo = (string?)item.Modelo,
            FechaEntrada = (DateTime)item.FechaEntrada,
            TiempoEsperado = (DateTime)item.TiempoEsperado,
            DanoEstimado = null,
            IdCliente = (int)item.IdCliente,
            NombreCliente = (string)item.NombreCliente,
            ApellidoCliente = (string?)item.ApellidoCliente,
            TelefonoCliente = (string?)item.TelefonoCliente,
            LugarProcedencia = (string?)item.LugarProcedencia,
            UsuarioIdResponsable = (int?)item.UsuarioIdResponsable,
            NombreResponsable = (string?)item.NombreResponsable,
            FechaInicio = (DateTime)item.FechaInicio,
            FechaEstimadaFinalizacion = (DateTime)item.FechaEstimadaFinalizacion,
            EstadoOperacion = estado,
            SolicitaEliminacion = solicitaBaja,
            MotivoEliminacion = motivo
        };
    }

    /// <summary>
    /// Registra un nuevo proyecto (Camión + Cliente + Operación) en una sola operación atómica.
    /// </summary>
    public async Task<ProyectoDetalleResponseDto> CrearProyectoAsync(CrearProyectoRequestDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Placas))
        {
            throw new InvalidOperationException("Las placas del camión son requeridas para registrar el proyecto.");
        }

        // 1. Resolver o Crear Cliente
        int idClienteFinal;
        if (dto.ClienteId.HasValue && dto.ClienteId.Value > 0)
        {
            var clienteExiste = await _clienteRepo.GetByIdAsync(dto.ClienteId.Value);
            if (clienteExiste == null)
            {
                throw new InvalidOperationException($"El cliente con ID {dto.ClienteId.Value} no existe.");
            }
            idClienteFinal = clienteExiste.IdCliente;
        }
        else
        {
            if (string.IsNullOrWhiteSpace(dto.NombreCliente))
            {
                throw new InvalidOperationException("Debe seleccionar un cliente existente o proporcionar el nombre de uno nuevo.");
            }

            var nuevoCliente = await _clienteRepo.CreateAsync(new CreateClienteDto
            {
                Nombre = dto.NombreCliente.Trim(),
                Apellido = dto.ApellidoCliente?.Trim() ?? string.Empty,
                NumTelefono = dto.TelefonoCliente?.Trim() ?? string.Empty,
                LugarProcedencia = dto.LugarProcedencia?.Trim() ?? "Local"
            });
            idClienteFinal = nuevoCliente.IdCliente;
        }

        // 2. Registrar el Camión
        var fechaEntrada = dto.FechaEntrada ?? DateTime.UtcNow;
        var tiempoEsperado = dto.TiempoEsperado ?? fechaEntrada.AddDays(7);

        var nuevoCamion = await _camionRepo.CreateAsync(new CreateCamionDto
        {
            ClienteId = idClienteFinal,
            Placas = dto.Placas.Trim().ToUpperInvariant(),
            Marca = dto.Marca?.Trim(),
            Modelo = dto.Modelo?.Trim(),
            FechaEntrada = fechaEntrada,
            TiempoEsperado = tiempoEsperado
        });

        // 3. Registrar la Operación del Proyecto
        var fechaEstimada = dto.FechaEstimadaFinalizacion ?? tiempoEsperado;
        var nuevaOperacion = await _operacionRepo.CreateAsync(new CreateOperacionDto
        {
            CamionId = nuevoCamion.IdCamion,
            UsuarioId = dto.UsuarioIdResponsable,
            FechaInicio = fechaEntrada,
            FechaEstimadaFinalizacion = fechaEstimada,
            EstadoOperacion = "Iniciado"
        });

        // 4. Retornar el proyecto completo
        var proyectoCreado = await GetByIdAsync(nuevaOperacion.IdOperacion);
        return proyectoCreado ?? throw new InvalidOperationException("Error al recuperar el proyecto creado.");
    }

    /// <summary>
    /// Edita información del proyecto (Camión y Operación).
    /// </summary>
    public async Task<bool> EditarProyectoAsync(int idProyecto, EditarProyectoRequestDto dto)
    {
        var operacion = await _operacionRepo.GetByIdAsync(idProyecto);
        if (operacion == null)
            return false;

        var camion = await _camionRepo.GetByIdAsync(operacion.CamionId);
        if (camion == null)
            return false;

        // Actualizar datos del camión
        await _camionRepo.UpdateAsync(camion.IdCamion, new CreateCamionDto
        {
            ClienteId = camion.ClienteId,
            Placas = string.IsNullOrWhiteSpace(dto.Placas) ? camion.Placas : dto.Placas.Trim().ToUpperInvariant(),
            Marca = dto.Marca?.Trim() ?? camion.Marca,
            Modelo = dto.Modelo?.Trim() ?? camion.Modelo,
            FechaEntrada = camion.FechaEntrada,
            TiempoEsperado = dto.TiempoEsperado ?? camion.TiempoEsperado
        });

        // Actualizar datos de la operación
        return await _operacionRepo.UpdateAsync(idProyecto, new CreateOperacionDto
        {
            CamionId = operacion.CamionId,
            UsuarioId = dto.UsuarioIdResponsable ?? operacion.UsuarioId,
            FechaInicio = operacion.FechaInicio,
            FechaEstimadaFinalizacion = dto.FechaEstimadaFinalizacion ?? operacion.FechaEstimadaFinalizacion,
            EstadoOperacion = dto.EstadoOperacion?.Trim() ?? operacion.EstadoOperacion ?? "En Proceso"
        });
    }

    /// <summary>
    /// Solicita la eliminación de un proyecto registrando el motivo para revisión del Administrador.
    /// </summary>
    public async Task<bool> SolicitarBajaAsync(int idProyecto, SolicitarBajaProyectoRequestDto dto, string usernameSolicitante)
    {
        var operacion = await _operacionRepo.GetByIdAsync(idProyecto);
        if (operacion == null)
            return false;

        string nuevoEstado = $"Solicitud_Baja: [{usernameSolicitante}] {dto.Motivo?.Trim()}";

        return await _operacionRepo.UpdateAsync(idProyecto, new CreateOperacionDto
        {
            CamionId = operacion.CamionId,
            UsuarioId = operacion.UsuarioId,
            FechaInicio = operacion.FechaInicio,
            FechaEstimadaFinalizacion = operacion.FechaEstimadaFinalizacion,
            EstadoOperacion = nuevoEstado
        });
    }

    /// <summary>
    /// Elimina o da de baja definitiva a un proyecto (requiere privilegios de Admin o Proyecto_Lider).
    /// </summary>
    public async Task<bool> EliminarProyectoAsync(int idProyecto)
    {
        var operacion = await _operacionRepo.GetByIdAsync(idProyecto);
        if (operacion == null)
            return false;

        // Marcado lógico a 'Cancelado / Eliminado' para proteger la integridad histórica
        return await _operacionRepo.UpdateAsync(idProyecto, new CreateOperacionDto
        {
            CamionId = operacion.CamionId,
            UsuarioId = operacion.UsuarioId,
            FechaInicio = operacion.FechaInicio,
            FechaEstimadaFinalizacion = operacion.FechaEstimadaFinalizacion,
            EstadoOperacion = "Eliminado"
        });
    }
}
