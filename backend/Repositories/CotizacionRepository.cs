using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface ICotizacionRepository
{
    Task<IEnumerable<Cotizacion>> GetAllAsync();
    Task<Cotizacion?> GetByIdAsync(int id);
    Task<Cotizacion> CreateAsync(CreateCotizacionDto dto);
    Task<bool> UpdateAsync(int id, CreateCotizacionDto dto);
    Task<bool> DeleteAsync(int id);
}

public class CotizacionRepository : ICotizacionRepository
{
    private readonly DapperContext _context;

    public CotizacionRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Cotizacion>> GetAllAsync()
    {
        const string query = "SELECT \"id_cotizacion\" AS \"IdCotizacion\", \"operacion_id\" AS \"OperacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"manoObraEstimada\" AS \"ManoObraEstimada\", \"costoEstimadoPiezas\" AS \"CostoEstimadoPiezas\", \"total\" AS \"Total\", \"estadoCotizacion\" AS \"EstadoCotizacion\" FROM COTIZACION;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<Cotizacion>(query);
    }

    public async Task<Cotizacion?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_cotizacion\" AS \"IdCotizacion\", \"operacion_id\" AS \"OperacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"manoObraEstimada\" AS \"ManoObraEstimada\", \"costoEstimadoPiezas\" AS \"CostoEstimadoPiezas\", \"total\" AS \"Total\", \"estadoCotizacion\" AS \"EstadoCotizacion\" FROM COTIZACION WHERE \"id_cotizacion\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Cotizacion>(query, new { Id = id });
    }

    public async Task<Cotizacion> CreateAsync(CreateCotizacionDto dto)
    {
        const string query = "INSERT INTO COTIZACION (\"operacion_id\", \"trabajador_id\", \"manoObraEstimada\", \"costoEstimadoPiezas\", \"total\", \"estadoCotizacion\") VALUES (@OperacionId, @TrabajadorId, @ManoObraEstimada, @CostoEstimadoPiezas, @Total, @EstadoCotizacion) RETURNING \"id_cotizacion\" AS \"IdCotizacion\", \"operacion_id\" AS \"OperacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"manoObraEstimada\" AS \"ManoObraEstimada\", \"costoEstimadoPiezas\" AS \"CostoEstimadoPiezas\", \"total\" AS \"Total\", \"estadoCotizacion\" AS \"EstadoCotizacion\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<Cotizacion>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateCotizacionDto dto)
    {
        const string query = "UPDATE COTIZACION SET \"operacion_id\" = @OperacionId, \"trabajador_id\" = @TrabajadorId, \"manoObraEstimada\" = @ManoObraEstimada, \"costoEstimadoPiezas\" = @CostoEstimadoPiezas, \"total\" = @Total, \"estadoCotizacion\" = @EstadoCotizacion WHERE \"id_cotizacion\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM COTIZACION WHERE \"id_cotizacion\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
