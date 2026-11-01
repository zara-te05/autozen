using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IDevolucionProveedorRepository
{
    Task<IEnumerable<DevolucionProveedor>> GetAllAsync();
    Task<DevolucionProveedor?> GetByIdAsync(int id);
    Task<DevolucionProveedor> CreateAsync(CreateDevolucionProveedorDto dto);
    Task<bool> UpdateAsync(int id, CreateDevolucionProveedorDto dto);
    Task<bool> DeleteAsync(int id);
}

public class DevolucionProveedorRepository : IDevolucionProveedorRepository
{
    private readonly DapperContext _context;

    public DevolucionProveedorRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<DevolucionProveedor>> GetAllAsync()
    {
        const string query = "SELECT \"id_devolucion\" AS \"IdDevolucion\", \"compra_id\" AS \"CompraId\", \"proveedor_id\" AS \"ProveedorId\", \"motivo\" AS \"Motivo\", \"fechaDevolucion\" AS \"FechaDevolucion\", \"estadoDevolucion\" AS \"EstadoDevolucion\", \"montoReembolso\" AS \"MontoReembolso\" FROM DEVOLUCION_PROVEEDOR;";
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<DevolucionProveedor>(query, transaction: tx));
    }

    public async Task<DevolucionProveedor?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_devolucion\" AS \"IdDevolucion\", \"compra_id\" AS \"CompraId\", \"proveedor_id\" AS \"ProveedorId\", \"motivo\" AS \"Motivo\", \"fechaDevolucion\" AS \"FechaDevolucion\", \"estadoDevolucion\" AS \"EstadoDevolucion\", \"montoReembolso\" AS \"MontoReembolso\" FROM DEVOLUCION_PROVEEDOR WHERE \"id_devolucion\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<DevolucionProveedor>(query, new { Id = id }, transaction: tx));
    }

    public async Task<DevolucionProveedor> CreateAsync(CreateDevolucionProveedorDto dto)
    {
        const string query = "INSERT INTO DEVOLUCION_PROVEEDOR (\"compra_id\", \"proveedor_id\", \"motivo\", \"fechaDevolucion\", \"estadoDevolucion\", \"montoReembolso\") VALUES (@CompraId, @ProveedorId, @Motivo, @FechaDevolucion, @EstadoDevolucion, @MontoReembolso) RETURNING \"id_devolucion\" AS \"IdDevolucion\", \"compra_id\" AS \"CompraId\", \"proveedor_id\" AS \"ProveedorId\", \"motivo\" AS \"Motivo\", \"fechaDevolucion\" AS \"FechaDevolucion\", \"estadoDevolucion\" AS \"EstadoDevolucion\", \"montoReembolso\" AS \"MontoReembolso\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<DevolucionProveedor>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateDevolucionProveedorDto dto)
    {
        const string query = "UPDATE DEVOLUCION_PROVEEDOR SET \"compra_id\" = @CompraId, \"proveedor_id\" = @ProveedorId, \"motivo\" = @Motivo, \"fechaDevolucion\" = @FechaDevolucion, \"estadoDevolucion\" = @EstadoDevolucion, \"montoReembolso\" = @MontoReembolso WHERE \"id_devolucion\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM DEVOLUCION_PROVEEDOR WHERE \"id_devolucion\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
