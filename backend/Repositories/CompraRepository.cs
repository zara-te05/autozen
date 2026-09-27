using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface ICompraRepository
{
    Task<IEnumerable<Compra>> GetAllAsync();
    Task<Compra?> GetByIdAsync(int id);
    Task<Compra> CreateAsync(CreateCompraDto dto);
    Task<bool> UpdateAsync(int id, CreateCompraDto dto);
    Task<bool> DeleteAsync(int id);
}

public class CompraRepository : ICompraRepository
{
    private readonly DapperContext _context;

    public CompraRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Compra>> GetAllAsync()
    {
        const string query = "SELECT \"id_compra\" AS \"IdCompra\", \"solicitud_compra_id\" AS \"SolicitudCompraId\", \"operacion_id\" AS \"OperacionId\", \"nombrePiezas\" AS \"NombrePiezas\", \"cantidadPiezas\" AS \"CantidadPiezas\", \"costoPiezas\" AS \"CostoPiezas\" FROM COMPRA;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<Compra>(query);
    }

    public async Task<Compra?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_compra\" AS \"IdCompra\", \"solicitud_compra_id\" AS \"SolicitudCompraId\", \"operacion_id\" AS \"OperacionId\", \"nombrePiezas\" AS \"NombrePiezas\", \"cantidadPiezas\" AS \"CantidadPiezas\", \"costoPiezas\" AS \"CostoPiezas\" FROM COMPRA WHERE \"id_compra\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Compra>(query, new { Id = id });
    }

    public async Task<Compra> CreateAsync(CreateCompraDto dto)
    {
        const string query = "INSERT INTO COMPRA (\"solicitud_compra_id\", \"operacion_id\", \"nombrePiezas\", \"cantidadPiezas\", \"costoPiezas\") VALUES (@SolicitudCompraId, @OperacionId, @NombrePiezas, @CantidadPiezas, @CostoPiezas) RETURNING \"id_compra\" AS \"IdCompra\", \"solicitud_compra_id\" AS \"SolicitudCompraId\", \"operacion_id\" AS \"OperacionId\", \"nombrePiezas\" AS \"NombrePiezas\", \"cantidadPiezas\" AS \"CantidadPiezas\", \"costoPiezas\" AS \"CostoPiezas\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<Compra>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateCompraDto dto)
    {
        const string query = "UPDATE COMPRA SET \"solicitud_compra_id\" = @SolicitudCompraId, \"operacion_id\" = @OperacionId, \"nombrePiezas\" = @NombrePiezas, \"cantidadPiezas\" = @CantidadPiezas, \"costoPiezas\" = @CostoPiezas WHERE \"id_compra\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM COMPRA WHERE \"id_compra\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
