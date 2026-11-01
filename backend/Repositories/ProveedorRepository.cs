using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IProveedorRepository
{
    Task<IEnumerable<Proveedor>> GetAllAsync();
    Task<Proveedor?> GetByIdAsync(int id);
    Task<Proveedor> CreateAsync(CreateProveedorDto dto);
    Task<bool> UpdateAsync(int id, CreateProveedorDto dto);
    Task<bool> DeleteAsync(int id);
}

public class ProveedorRepository : IProveedorRepository
{
    private readonly DapperContext _context;

    public ProveedorRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Proveedor>> GetAllAsync()
    {
        const string query = "SELECT \"id_proveedor\" AS \"IdProveedor\", \"nombreProveedor\" AS \"NombreProveedor\", \"contacto\" AS \"Contacto\", direccion AS \"Direccion\", \"tiempoEntregaPromedioDias\" AS \"TiempoEntregaPromedioDias\", \"precioPromedio\" AS \"PrecioPromedio\" FROM PROVEEDOR;";
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<Proveedor>(query, transaction: tx));
    }

    public async Task<Proveedor?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_proveedor\" AS \"IdProveedor\", \"nombreProveedor\" AS \"NombreProveedor\", \"contacto\" AS \"Contacto\", direccion AS \"Direccion\", \"tiempoEntregaPromedioDias\" AS \"TiempoEntregaPromedioDias\", \"precioPromedio\" AS \"PrecioPromedio\" FROM PROVEEDOR WHERE \"id_proveedor\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<Proveedor>(query, new { Id = id }, transaction: tx));
    }

    public async Task<Proveedor> CreateAsync(CreateProveedorDto dto)
    {
        const string query = "INSERT INTO PROVEEDOR (\"nombreProveedor\", \"contacto\", direccion, \"tiempoEntregaPromedioDias\", \"precioPromedio\") VALUES (@NombreProveedor, @Contacto, @Direccion, @TiempoEntregaPromedioDias, @PrecioPromedio) RETURNING \"id_proveedor\" AS \"IdProveedor\", \"nombreProveedor\" AS \"NombreProveedor\", \"contacto\" AS \"Contacto\", direccion AS \"Direccion\", \"tiempoEntregaPromedioDias\" AS \"TiempoEntregaPromedioDias\", \"precioPromedio\" AS \"PrecioPromedio\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<Proveedor>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateProveedorDto dto)
    {
        const string query = "UPDATE PROVEEDOR SET \"nombreProveedor\" = @NombreProveedor, \"contacto\" = @Contacto, direccion = @Direccion, \"tiempoEntregaPromedioDias\" = @TiempoEntregaPromedioDias, \"precioPromedio\" = @PrecioPromedio WHERE \"id_proveedor\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM PROVEEDOR WHERE \"id_proveedor\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
