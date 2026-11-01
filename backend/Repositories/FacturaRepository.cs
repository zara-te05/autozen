using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IFacturaRepository
{
    Task<IEnumerable<Factura>> GetAllAsync();
    Task<Factura?> GetByIdAsync(int id);
    Task<Factura> CreateAsync(CreateFacturaDto dto);
    Task<bool> UpdateAsync(int id, CreateFacturaDto dto);
    Task<bool> DeleteAsync(int id);
}

public class FacturaRepository : IFacturaRepository
{
    private readonly DapperContext _context;

    public FacturaRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Factura>> GetAllAsync()
    {
        const string query = "SELECT \"id_factura\" AS \"IdFactura\", \"operacion_id\" AS \"OperacionId\", \"fechaEmision\" AS \"FechaEmision\", \"montoTotal\" AS \"MontoTotal\", \"estadoPago\" AS \"EstadoPago\" FROM FACTURA;";
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<Factura>(query, transaction: tx));
    }

    public async Task<Factura?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_factura\" AS \"IdFactura\", \"operacion_id\" AS \"OperacionId\", \"fechaEmision\" AS \"FechaEmision\", \"montoTotal\" AS \"MontoTotal\", \"estadoPago\" AS \"EstadoPago\" FROM FACTURA WHERE \"id_factura\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<Factura>(query, new { Id = id }, transaction: tx));
    }

    public async Task<Factura> CreateAsync(CreateFacturaDto dto)
    {
        const string query = "INSERT INTO FACTURA (\"operacion_id\", \"fechaEmision\", \"montoTotal\", \"estadoPago\") VALUES (@OperacionId, @FechaEmision, @MontoTotal, @EstadoPago) RETURNING \"id_factura\" AS \"IdFactura\", \"operacion_id\" AS \"OperacionId\", \"fechaEmision\" AS \"FechaEmision\", \"montoTotal\" AS \"MontoTotal\", \"estadoPago\" AS \"EstadoPago\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<Factura>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateFacturaDto dto)
    {
        const string query = "UPDATE FACTURA SET \"operacion_id\" = @OperacionId, \"fechaEmision\" = @FechaEmision, \"montoTotal\" = @MontoTotal, \"estadoPago\" = @EstadoPago WHERE \"id_factura\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM FACTURA WHERE \"id_factura\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
