using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IEquipoAlmacenRepository
{
    Task<IEnumerable<EquipoAlmacen>> GetAllAsync();
    Task<EquipoAlmacen?> GetByIdAsync(int id);
    Task<EquipoAlmacen> CreateAsync(CreateEquipoAlmacenDto dto);
    Task<bool> UpdateAsync(int id, CreateEquipoAlmacenDto dto);
    Task<bool> DeleteAsync(int id);

    /// <summary>
    /// Marca la herramienta como devuelta solo si sigue en uso. Devuelve false si ya estaba devuelta.
    /// </summary>
    Task<bool> MarcarDevueltaAsync(int id, string estadoDevuelto);
}

public class EquipoAlmacenRepository : IEquipoAlmacenRepository
{
    private readonly DapperContext _context;

    public EquipoAlmacenRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<EquipoAlmacen>> GetAllAsync()
    {
        const string query = "SELECT \"id_equipo\" AS \"IdEquipo\", \"operacion_id\" AS \"OperacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"nombreHerramienta\" AS \"NombreHerramienta\", \"estadoSalida\" AS \"EstadoSalida\", \"estadoDevuelto\" AS \"EstadoDevuelto\" FROM EQUIPO_ALMACEN;";
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<EquipoAlmacen>(query, transaction: tx));
    }

    public async Task<EquipoAlmacen?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_equipo\" AS \"IdEquipo\", \"operacion_id\" AS \"OperacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"nombreHerramienta\" AS \"NombreHerramienta\", \"estadoSalida\" AS \"EstadoSalida\", \"estadoDevuelto\" AS \"EstadoDevuelto\" FROM EQUIPO_ALMACEN WHERE \"id_equipo\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<EquipoAlmacen>(query, new { Id = id }, transaction: tx));
    }

    public async Task<EquipoAlmacen> CreateAsync(CreateEquipoAlmacenDto dto)
    {
        const string query = "INSERT INTO EQUIPO_ALMACEN (\"operacion_id\", \"trabajador_id\", \"nombreHerramienta\", \"estadoSalida\", \"estadoDevuelto\") VALUES (@OperacionId, @TrabajadorId, @NombreHerramienta, @EstadoSalida, @EstadoDevuelto) RETURNING \"id_equipo\" AS \"IdEquipo\", \"operacion_id\" AS \"OperacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"nombreHerramienta\" AS \"NombreHerramienta\", \"estadoSalida\" AS \"EstadoSalida\", \"estadoDevuelto\" AS \"EstadoDevuelto\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<EquipoAlmacen>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateEquipoAlmacenDto dto)
    {
        const string query = "UPDATE EQUIPO_ALMACEN SET \"operacion_id\" = @OperacionId, \"trabajador_id\" = @TrabajadorId, \"nombreHerramienta\" = @NombreHerramienta, \"estadoSalida\" = @EstadoSalida, \"estadoDevuelto\" = @EstadoDevuelto WHERE \"id_equipo\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM EQUIPO_ALMACEN WHERE \"id_equipo\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> MarcarDevueltaAsync(int id, string estadoDevuelto)
    {
        const string query = "UPDATE EQUIPO_ALMACEN SET \"estadoDevuelto\" = @EstadoDevuelto WHERE \"id_equipo\" = @Id AND (\"estadoDevuelto\" IS NULL OR \"estadoDevuelto\" IN ('En Uso', 'Pendiente'));";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id, EstadoDevuelto = estadoDevuelto }, transaction: tx));
        return rowsAffected > 0;
    }
}
