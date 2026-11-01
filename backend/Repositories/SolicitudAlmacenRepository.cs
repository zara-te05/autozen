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
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<SolicitudAlmacen>(query, transaction: tx));
    }

    public async Task<SolicitudAlmacen?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_solicitud_almacen\" AS \"IdSolicitudAlmacen\", \"almacen_id\" AS \"AlmacenId\", \"operacion_id\" AS \"OperacionId\", \"cantidadSolicitada\" AS \"CantidadSolicitada\", \"fechaSolicitud\" AS \"FechaSolicitud\" FROM SOLICITUD_ALMACEN WHERE \"id_solicitud_almacen\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<SolicitudAlmacen>(query, new { Id = id }, transaction: tx));
    }

    public async Task<SolicitudAlmacen> CreateAsync(CreateSolicitudAlmacenDto dto)
    {
        const string query = "INSERT INTO SOLICITUD_ALMACEN (\"almacen_id\", \"operacion_id\", \"cantidadSolicitada\", \"fechaSolicitud\") VALUES (@AlmacenId, @OperacionId, @CantidadSolicitada, @FechaSolicitud) RETURNING \"id_solicitud_almacen\" AS \"IdSolicitudAlmacen\", \"almacen_id\" AS \"AlmacenId\", \"operacion_id\" AS \"OperacionId\", \"cantidadSolicitada\" AS \"CantidadSolicitada\", \"fechaSolicitud\" AS \"FechaSolicitud\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<SolicitudAlmacen>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateSolicitudAlmacenDto dto)
    {
        const string query = "UPDATE SOLICITUD_ALMACEN SET \"almacen_id\" = @AlmacenId, \"operacion_id\" = @OperacionId, \"cantidadSolicitada\" = @CantidadSolicitada, \"fechaSolicitud\" = @FechaSolicitud WHERE \"id_solicitud_almacen\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM SOLICITUD_ALMACEN WHERE \"id_solicitud_almacen\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
