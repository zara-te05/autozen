using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IClienteRepository
{
    Task<IEnumerable<Cliente>> GetAllAsync();
    Task<Cliente?> GetByIdAsync(int id);
    Task<Cliente> CreateAsync(CreateClienteDto dto);
    Task<bool> UpdateAsync(int id, CreateClienteDto dto);
    Task<bool> DeleteAsync(int id);
}

public class ClienteRepository : IClienteRepository
{
    private readonly DapperContext _context;

    public ClienteRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Cliente>> GetAllAsync()
    {
        const string query = "SELECT \"id_cliente\" AS \"IdCliente\", \"nombre\" AS \"Nombre\", \"apellido\" AS \"Apellido\", \"numTelefono\" AS \"NumTelefono\", \"metodoContactoAlternativo\" AS \"MetodoContactoAlternativo\", \"lugarProcedencia\" AS \"LugarProcedencia\" FROM CLIENTE;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<Cliente>(query);
    }

    public async Task<Cliente?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_cliente\" AS \"IdCliente\", \"nombre\" AS \"Nombre\", \"apellido\" AS \"Apellido\", \"numTelefono\" AS \"NumTelefono\", \"metodoContactoAlternativo\" AS \"MetodoContactoAlternativo\", \"lugarProcedencia\" AS \"LugarProcedencia\" FROM CLIENTE WHERE \"id_cliente\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Cliente>(query, new { Id = id });
    }

    public async Task<Cliente> CreateAsync(CreateClienteDto dto)
    {
        const string query = "INSERT INTO CLIENTE (\"nombre\", \"apellido\", \"numTelefono\", \"metodoContactoAlternativo\", \"lugarProcedencia\") VALUES (@Nombre, @Apellido, @NumTelefono, @MetodoContactoAlternativo, @LugarProcedencia) RETURNING \"id_cliente\" AS \"IdCliente\", \"nombre\" AS \"Nombre\", \"apellido\" AS \"Apellido\", \"numTelefono\" AS \"NumTelefono\", \"metodoContactoAlternativo\" AS \"MetodoContactoAlternativo\", \"lugarProcedencia\" AS \"LugarProcedencia\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<Cliente>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateClienteDto dto)
    {
        const string query = "UPDATE CLIENTE SET \"nombre\" = @Nombre, \"apellido\" = @Apellido, \"numTelefono\" = @NumTelefono, \"metodoContactoAlternativo\" = @MetodoContactoAlternativo, \"lugarProcedencia\" = @LugarProcedencia WHERE \"id_cliente\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM CLIENTE WHERE \"id_cliente\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
