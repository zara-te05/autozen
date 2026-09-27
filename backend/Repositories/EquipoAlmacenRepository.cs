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
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<EquipoAlmacen>(query);
    }

    public async Task<EquipoAlmacen?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_equipo\" AS \"IdEquipo\", \"operacion_id\" AS \"OperacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"nombreHerramienta\" AS \"NombreHerramienta\", \"estadoSalida\" AS \"EstadoSalida\", \"estadoDevuelto\" AS \"EstadoDevuelto\" FROM EQUIPO_ALMACEN WHERE \"id_equipo\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<EquipoAlmacen>(query, new { Id = id });
    }

    public async Task<EquipoAlmacen> CreateAsync(CreateEquipoAlmacenDto dto)
    {
        const string query = "INSERT INTO EQUIPO_ALMACEN (\"operacion_id\", \"trabajador_id\", \"nombreHerramienta\", \"estadoSalida\", \"estadoDevuelto\") VALUES (@OperacionId, @TrabajadorId, @NombreHerramienta, @EstadoSalida, @EstadoDevuelto) RETURNING \"id_equipo\" AS \"IdEquipo\", \"operacion_id\" AS \"OperacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"nombreHerramienta\" AS \"NombreHerramienta\", \"estadoSalida\" AS \"EstadoSalida\", \"estadoDevuelto\" AS \"EstadoDevuelto\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<EquipoAlmacen>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateEquipoAlmacenDto dto)
    {
        const string query = "UPDATE EQUIPO_ALMACEN SET \"operacion_id\" = @OperacionId, \"trabajador_id\" = @TrabajadorId, \"nombreHerramienta\" = @NombreHerramienta, \"estadoSalida\" = @EstadoSalida, \"estadoDevuelto\" = @EstadoDevuelto WHERE \"id_equipo\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM EQUIPO_ALMACEN WHERE \"id_equipo\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
