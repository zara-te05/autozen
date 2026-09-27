using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface ISolicitudAlmacenRepository
{
    Task<IEnumerable<SolicitudAlmacen>> GetAllAsync();
    Task<SolicitudAlmacen?> GetByIdAsync(int id);
    Task<SolicitudAlmacen> CreateAsync(CreateSolicitudAlmacenDto dto);
    Task<bool> UpdateAsync(int id, CreateSolicitudAlmacenDto dto);
    Task<bool> DeleteAsync(int id);
}

public class SolicitudAlmacenRepository : ISolicitudAlmacenRepository
{
    private readonly DapperContext _context;

    public SolicitudAlmacenRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<SolicitudAlmacen>> GetAllAsync()
    {
        const string query = "SELECT \"id_solicitud_almacen\" AS \"IdSolicitudAlmacen\", \"almacen_id\" AS \"AlmacenId\", \"operacion_id\" AS \"OperacionId\", \"cantidadSolicitada\" AS \"CantidadSolicitada\", \"fechaSolicitud\" AS \"FechaSolicitud\" FROM SOLICITUD_ALMACEN;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<SolicitudAlmacen>(query);
    }

    public async Task<SolicitudAlmacen?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_solicitud_almacen\" AS \"IdSolicitudAlmacen\", \"almacen_id\" AS \"AlmacenId\", \"operacion_id\" AS \"OperacionId\", \"cantidadSolicitada\" AS \"CantidadSolicitada\", \"fechaSolicitud\" AS \"FechaSolicitud\" FROM SOLICITUD_ALMACEN WHERE \"id_solicitud_almacen\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<SolicitudAlmacen>(query, new { Id = id });
    }

    public async Task<SolicitudAlmacen> CreateAsync(CreateSolicitudAlmacenDto dto)
    {
        const string query = "INSERT INTO SOLICITUD_ALMACEN (\"almacen_id\", \"operacion_id\", \"cantidadSolicitada\", \"fechaSolicitud\") VALUES (@AlmacenId, @OperacionId, @CantidadSolicitada, @FechaSolicitud) RETURNING \"id_solicitud_almacen\" AS \"IdSolicitudAlmacen\", \"almacen_id\" AS \"AlmacenId\", \"operacion_id\" AS \"OperacionId\", \"cantidadSolicitada\" AS \"CantidadSolicitada\", \"fechaSolicitud\" AS \"FechaSolicitud\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<SolicitudAlmacen>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateSolicitudAlmacenDto dto)
    {
        const string query = "UPDATE SOLICITUD_ALMACEN SET \"almacen_id\" = @AlmacenId, \"operacion_id\" = @OperacionId, \"cantidadSolicitada\" = @CantidadSolicitada, \"fechaSolicitud\" = @FechaSolicitud WHERE \"id_solicitud_almacen\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM SOLICITUD_ALMACEN WHERE \"id_solicitud_almacen\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
