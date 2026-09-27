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
        const string query = "SELECT \"id_proveedor\" AS \"IdProveedor\", \"nombreProveedor\" AS \"NombreProveedor\", \"contacto\" AS \"Contacto\", \"tiempoEntregaPromedioDias\" AS \"TiempoEntregaPromedioDias\", \"precioPromedio\" AS \"PrecioPromedio\" FROM PROVEEDOR;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<Proveedor>(query);
    }

    public async Task<Proveedor?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_proveedor\" AS \"IdProveedor\", \"nombreProveedor\" AS \"NombreProveedor\", \"contacto\" AS \"Contacto\", \"tiempoEntregaPromedioDias\" AS \"TiempoEntregaPromedioDias\", \"precioPromedio\" AS \"PrecioPromedio\" FROM PROVEEDOR WHERE \"id_proveedor\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Proveedor>(query, new { Id = id });
    }

    public async Task<Proveedor> CreateAsync(CreateProveedorDto dto)
    {
        const string query = "INSERT INTO PROVEEDOR (\"nombreProveedor\", \"contacto\", \"tiempoEntregaPromedioDias\", \"precioPromedio\") VALUES (@NombreProveedor, @Contacto, @TiempoEntregaPromedioDias, @PrecioPromedio) RETURNING \"id_proveedor\" AS \"IdProveedor\", \"nombreProveedor\" AS \"NombreProveedor\", \"contacto\" AS \"Contacto\", \"tiempoEntregaPromedioDias\" AS \"TiempoEntregaPromedioDias\", \"precioPromedio\" AS \"PrecioPromedio\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<Proveedor>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateProveedorDto dto)
    {
        const string query = "UPDATE PROVEEDOR SET \"nombreProveedor\" = @NombreProveedor, \"contacto\" = @Contacto, \"tiempoEntregaPromedioDias\" = @TiempoEntregaPromedioDias, \"precioPromedio\" = @PrecioPromedio WHERE \"id_proveedor\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM PROVEEDOR WHERE \"id_proveedor\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
