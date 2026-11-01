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
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<Compra>(query, transaction: tx));
    }

    public async Task<Compra?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_compra\" AS \"IdCompra\", \"solicitud_compra_id\" AS \"SolicitudCompraId\", \"operacion_id\" AS \"OperacionId\", \"nombrePiezas\" AS \"NombrePiezas\", \"cantidadPiezas\" AS \"CantidadPiezas\", \"costoPiezas\" AS \"CostoPiezas\" FROM COMPRA WHERE \"id_compra\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<Compra>(query, new { Id = id }, transaction: tx));
    }

    public async Task<Compra> CreateAsync(CreateCompraDto dto)
    {
        const string query = "INSERT INTO COMPRA (\"solicitud_compra_id\", \"operacion_id\", \"nombrePiezas\", \"cantidadPiezas\", \"costoPiezas\") VALUES (@SolicitudCompraId, @OperacionId, @NombrePiezas, @CantidadPiezas, @CostoPiezas) RETURNING \"id_compra\" AS \"IdCompra\", \"solicitud_compra_id\" AS \"SolicitudCompraId\", \"operacion_id\" AS \"OperacionId\", \"nombrePiezas\" AS \"NombrePiezas\", \"cantidadPiezas\" AS \"CantidadPiezas\", \"costoPiezas\" AS \"CostoPiezas\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<Compra>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateCompraDto dto)
    {
        const string query = "UPDATE COMPRA SET \"solicitud_compra_id\" = @SolicitudCompraId, \"operacion_id\" = @OperacionId, \"nombrePiezas\" = @NombrePiezas, \"cantidadPiezas\" = @CantidadPiezas, \"costoPiezas\" = @CostoPiezas WHERE \"id_compra\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM COMPRA WHERE \"id_compra\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
