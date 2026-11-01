using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IMovimientoAlmacenRepository
{
    Task<IEnumerable<MovimientoAlmacen>> GetAllAsync();
    Task<MovimientoAlmacen?> GetByIdAsync(int id);
    Task<MovimientoAlmacen> CreateAsync(CreateMovimientoAlmacenDto dto);
    Task<bool> UpdateAsync(int id, CreateMovimientoAlmacenDto dto);
    Task<bool> DeleteAsync(int id);
}

public class MovimientoAlmacenRepository : IMovimientoAlmacenRepository
{
    private readonly DapperContext _context;

    public MovimientoAlmacenRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<MovimientoAlmacen>> GetAllAsync()
    {
        const string query = "SELECT \"id_movimiento\" AS \"IdMovimiento\", \"almacen_id\" AS \"AlmacenId\", \"compra_id\" AS \"CompraId\", \"solicitud_almacen_id\" AS \"SolicitudAlmacenId\", \"tipoMovimiento\" AS \"TipoMovimiento\", \"cantidad\" AS \"Cantidad\", \"fechaMovimiento\" AS \"FechaMovimiento\" FROM MOVIMIENTO_ALMACEN;";
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<MovimientoAlmacen>(query, transaction: tx));
    }

    public async Task<MovimientoAlmacen?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_movimiento\" AS \"IdMovimiento\", \"almacen_id\" AS \"AlmacenId\", \"compra_id\" AS \"CompraId\", \"solicitud_almacen_id\" AS \"SolicitudAlmacenId\", \"tipoMovimiento\" AS \"TipoMovimiento\", \"cantidad\" AS \"Cantidad\", \"fechaMovimiento\" AS \"FechaMovimiento\" FROM MOVIMIENTO_ALMACEN WHERE \"id_movimiento\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<MovimientoAlmacen>(query, new { Id = id }, transaction: tx));
    }

    public async Task<MovimientoAlmacen> CreateAsync(CreateMovimientoAlmacenDto dto)
    {
        const string query = "INSERT INTO MOVIMIENTO_ALMACEN (\"almacen_id\", \"compra_id\", \"solicitud_almacen_id\", \"tipoMovimiento\", \"cantidad\", \"fechaMovimiento\") VALUES (@AlmacenId, @CompraId, @SolicitudAlmacenId, @TipoMovimiento, @Cantidad, @FechaMovimiento) RETURNING \"id_movimiento\" AS \"IdMovimiento\", \"almacen_id\" AS \"AlmacenId\", \"compra_id\" AS \"CompraId\", \"solicitud_almacen_id\" AS \"SolicitudAlmacenId\", \"tipoMovimiento\" AS \"TipoMovimiento\", \"cantidad\" AS \"Cantidad\", \"fechaMovimiento\" AS \"FechaMovimiento\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<MovimientoAlmacen>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateMovimientoAlmacenDto dto)
    {
        const string query = "UPDATE MOVIMIENTO_ALMACEN SET \"almacen_id\" = @AlmacenId, \"compra_id\" = @CompraId, \"solicitud_almacen_id\" = @SolicitudAlmacenId, \"tipoMovimiento\" = @TipoMovimiento, \"cantidad\" = @Cantidad, \"fechaMovimiento\" = @FechaMovimiento WHERE \"id_movimiento\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM MOVIMIENTO_ALMACEN WHERE \"id_movimiento\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
