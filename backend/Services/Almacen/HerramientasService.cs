using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Dapper;

namespace Autozen.Api.Services;

public class HerramientasService
{
    private readonly DapperContext _context;
    private readonly IEquipoAlmacenRepository _equipoRepo;
    private readonly IOperacionRepository _operacionRepo;

    public HerramientasService(
        DapperContext context,
        IEquipoAlmacenRepository equipoRepo,
        IOperacionRepository operacionRepo)
    {
        _context = context;
        _equipoRepo = equipoRepo;
        _operacionRepo = operacionRepo;
    }

    /// <summary>
    /// Registra la salida y préstamo de una herramienta para su uso en un proyecto, indicando estado físico y responsable.
    /// </summary>
    public async Task<HerramientaDetalleResponseDto> PrestarHerramientaAsync(PrestarHerramientaRequestDto dto)
    {
        if (dto.OperacionId <= 0)
            throw new InvalidOperationException("Debe especificar un ID de proyecto válido.");

        if (string.IsNullOrWhiteSpace(dto.NombreHerramienta))
            throw new InvalidOperationException("El nombre o descripción de la herramienta es requerido.");

        var operacion = await _operacionRepo.GetByIdAsync(dto.OperacionId);
        if (operacion == null)
            throw new InvalidOperationException($"El proyecto #{dto.OperacionId} no existe.");

        var fechaSalida = dto.FechaSalida ?? DateTime.UtcNow;
        string estadoSalida = string.IsNullOrWhiteSpace(dto.EstadoSalida) ? "Operativa" : dto.EstadoSalida.Trim();

        // Al prestarse, el estado de devolución inicia como 'En Uso'
        var nuevoPrestamo = new CreateEquipoAlmacenDto
        {
            OperacionId = dto.OperacionId,
            TrabajadorId = dto.TrabajadorId,
            NombreHerramienta = dto.NombreHerramienta.Trim(),
            EstadoSalida = $"{estadoSalida} [Salida: {fechaSalida:yyyy-MM-dd HH:mm}]",
            EstadoDevuelto = "En Uso"
        };

        var creado = await _equipoRepo.CreateAsync(nuevoPrestamo);
        var detalle = await GetHerramientaByIdAsync(creado.IdEquipo);

        return detalle ?? throw new InvalidOperationException("Error al recuperar el préstamo registrado.");
    }

    /// <summary>
    /// Registra la devolución de la herramienta evaluando su estado de retorno y hora exacta.
    /// </summary>
    public async Task<bool> DevolverHerramientaAsync(int idEquipo, DevolverHerramientaRequestDto dto)
    {
        var herramienta = await _equipoRepo.GetByIdAsync(idEquipo);
        if (herramienta == null)
            return false;

        var fechaRetorno = dto.FechaDevolucion ?? DateTime.UtcNow;
        string estadoFinal = string.IsNullOrWhiteSpace(dto.EstadoDevuelto) ? "Devuelta Operativa" : dto.EstadoDevuelto.Trim();

        string estadoDevueltoCompuesto = $"{estadoFinal} [Retorno: {fechaRetorno:yyyy-MM-dd HH:mm}]";

        return await _equipoRepo.UpdateAsync(idEquipo, new CreateEquipoAlmacenDto
        {
            OperacionId = herramienta.OperacionId,
            TrabajadorId = herramienta.TrabajadorId,
            NombreHerramienta = herramienta.NombreHerramienta,
            EstadoSalida = herramienta.EstadoSalida ?? "Operativa",
            EstadoDevuelto = estadoDevueltoCompuesto
        });
    }

    /// <summary>
    /// Consulta todas las herramientas que están actualmente prestadas en el taller y no han sido devueltas.
    /// </summary>
    public async Task<IEnumerable<HerramientaDetalleResponseDto>> GetHerramientasEnUsoAsync()
    {
        var todas = await GetAllHerramientasAsync();
        return todas.Where(h => !h.EstaDevuelta);
    }

    /// <summary>
    /// Consulta el historial completo de herramientas prestadas para un proyecto en específico.
    /// </summary>
    public async Task<IEnumerable<HerramientaDetalleResponseDto>> GetHerramientasPorProyectoAsync(int idProyecto)
    {
        var todas = await GetAllHerramientasAsync();
        return todas.Where(h => h.OperacionId == idProyecto);
    }

    /// <summary>
    /// Obtiene el detalle de un préstamo de herramienta por ID.
    /// </summary>
    public async Task<HerramientaDetalleResponseDto?> GetHerramientaByIdAsync(int idEquipo)
    {
        const string query = @"
            SELECT 
                e.""id_equipo"" AS ""IdEquipo"",
                e.""operacion_id"" AS ""OperacionId"",
                cam.""placas"" AS ""PlacasCamion"",
                e.""trabajador_id"" AS ""TrabajadorId"",
                TRIM(COALESCE(t.""nombreTrabajador"", '') || ' ' || COALESCE(t.""apellidoTrabajador"", '')) AS ""NombreTrabajador"",
                e.""nombreHerramienta"" AS ""NombreHerramienta"",
                e.""estadoSalida"" AS ""EstadoSalida"",
                e.""estadoDevuelto"" AS ""EstadoDevuelto""
            FROM EQUIPO_ALMACEN e
            INNER JOIN OPERACIONES o ON e.""operacion_id"" = o.""id_operacion""
            INNER JOIN CAMION cam ON o.""camion_id"" = cam.""id_camion""
            LEFT JOIN TRABAJADOR t ON e.""trabajador_id"" = t.""id_trabajador""
            WHERE e.""id_equipo"" = @Id;";

        using var connection = _context.CreateConnection();
        var item = await connection.QueryFirstOrDefaultAsync<dynamic>(query, new { Id = idEquipo });

        return item == null ? null : MapearADetalle(item);
    }

    /// <summary>
    /// Lista el historial completo de herramientas prestadas en el taller con auditoría de estados.
    /// </summary>
    public async Task<IEnumerable<HerramientaDetalleResponseDto>> GetAllHerramientasAsync()
    {
        const string query = @"
            SELECT 
                e.""id_equipo"" AS ""IdEquipo"",
                e.""operacion_id"" AS ""OperacionId"",
                cam.""placas"" AS ""PlacasCamion"",
                e.""trabajador_id"" AS ""TrabajadorId"",
                TRIM(COALESCE(t.""nombreTrabajador"", '') || ' ' || COALESCE(t.""apellidoTrabajador"", '')) AS ""NombreTrabajador"",
                e.""nombreHerramienta"" AS ""NombreHerramienta"",
                e.""estadoSalida"" AS ""EstadoSalida"",
                e.""estadoDevuelto"" AS ""EstadoDevuelto""
            FROM EQUIPO_ALMACEN e
            INNER JOIN OPERACIONES o ON e.""operacion_id"" = o.""id_operacion""
            INNER JOIN CAMION cam ON o.""camion_id"" = cam.""id_camion""
            LEFT JOIN TRABAJADOR t ON e.""trabajador_id"" = t.""id_trabajador""
            ORDER BY e.""id_equipo"" DESC;";

        using var connection = _context.CreateConnection();
        var lista = await connection.QueryAsync<dynamic>(query);

        return lista.Select(MapearADetalle);
    }

    private static HerramientaDetalleResponseDto MapearADetalle(dynamic item)
    {
        string estadoSalida = (string)(item.EstadoSalida ?? "Operativa");
        string estadoDevuelto = (string)(item.EstadoDevuelto ?? "En Uso");
        bool devuelta = !estadoDevuelto.Equals("En Uso", StringComparison.OrdinalIgnoreCase) &&
                        !estadoDevuelto.Equals("Pendiente", StringComparison.OrdinalIgnoreCase);

        return new HerramientaDetalleResponseDto
        {
            IdEquipo = (int)item.IdEquipo,
            OperacionId = (int)item.OperacionId,
            PlacasCamion = (string?)item.PlacasCamion,
            TrabajadorId = (int?)item.TrabajadorId,
            NombreTrabajador = string.IsNullOrWhiteSpace((string?)item.NombreTrabajador) ? "No Asignado" : (string)item.NombreTrabajador,
            NombreHerramienta = (string)item.NombreHerramienta,
            EstadoSalida = estadoSalida,
            EstadoDevuelto = estadoDevuelto,
            FechaSalida = null,
            FechaDevolucion = null,
            EstaDevuelta = devuelta
        };
    }
}
