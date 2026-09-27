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
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<Factura>(query);
    }

    public async Task<Factura?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_factura\" AS \"IdFactura\", \"operacion_id\" AS \"OperacionId\", \"fechaEmision\" AS \"FechaEmision\", \"montoTotal\" AS \"MontoTotal\", \"estadoPago\" AS \"EstadoPago\" FROM FACTURA WHERE \"id_factura\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Factura>(query, new { Id = id });
    }

    public async Task<Factura> CreateAsync(CreateFacturaDto dto)
    {
        const string query = "INSERT INTO FACTURA (\"operacion_id\", \"fechaEmision\", \"montoTotal\", \"estadoPago\") VALUES (@OperacionId, @FechaEmision, @MontoTotal, @EstadoPago) RETURNING \"id_factura\" AS \"IdFactura\", \"operacion_id\" AS \"OperacionId\", \"fechaEmision\" AS \"FechaEmision\", \"montoTotal\" AS \"MontoTotal\", \"estadoPago\" AS \"EstadoPago\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<Factura>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateFacturaDto dto)
    {
        const string query = "UPDATE FACTURA SET \"operacion_id\" = @OperacionId, \"fechaEmision\" = @FechaEmision, \"montoTotal\" = @MontoTotal, \"estadoPago\" = @EstadoPago WHERE \"id_factura\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM FACTURA WHERE \"id_factura\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
