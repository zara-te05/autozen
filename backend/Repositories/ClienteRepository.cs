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
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<Cliente>(query, transaction: tx));
    }

    public async Task<Cliente?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_cliente\" AS \"IdCliente\", \"nombre\" AS \"Nombre\", \"apellido\" AS \"Apellido\", \"numTelefono\" AS \"NumTelefono\", \"metodoContactoAlternativo\" AS \"MetodoContactoAlternativo\", \"lugarProcedencia\" AS \"LugarProcedencia\" FROM CLIENTE WHERE \"id_cliente\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<Cliente>(query, new { Id = id }, transaction: tx));
    }

    public async Task<Cliente> CreateAsync(CreateClienteDto dto)
    {
        const string query = "INSERT INTO CLIENTE (\"nombre\", \"apellido\", \"numTelefono\", \"metodoContactoAlternativo\", \"lugarProcedencia\") VALUES (@Nombre, @Apellido, @NumTelefono, @MetodoContactoAlternativo, @LugarProcedencia) RETURNING \"id_cliente\" AS \"IdCliente\", \"nombre\" AS \"Nombre\", \"apellido\" AS \"Apellido\", \"numTelefono\" AS \"NumTelefono\", \"metodoContactoAlternativo\" AS \"MetodoContactoAlternativo\", \"lugarProcedencia\" AS \"LugarProcedencia\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<Cliente>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateClienteDto dto)
    {
        const string query = "UPDATE CLIENTE SET \"nombre\" = @Nombre, \"apellido\" = @Apellido, \"numTelefono\" = @NumTelefono, \"metodoContactoAlternativo\" = @MetodoContactoAlternativo, \"lugarProcedencia\" = @LugarProcedencia WHERE \"id_cliente\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM CLIENTE WHERE \"id_cliente\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
