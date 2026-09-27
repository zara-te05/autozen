using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IUsuarioRepository
{
    Task<IEnumerable<Usuario>> GetAllAsync();
    Task<Usuario?> GetByIdAsync(int id);
    Task<Usuario> CreateAsync(CreateUsuarioDto dto);
    Task<bool> UpdateAsync(int id, CreateUsuarioDto dto);
    Task<bool> DeleteAsync(int id);
}

public class UsuarioRepository : IUsuarioRepository
{
    private readonly DapperContext _context;

    public UsuarioRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Usuario>> GetAllAsync()
    {
        const string query = "SELECT \"id_usuario\" AS \"IdUsuario\", \"nombre\" AS \"Nombre\", \"rol\" AS \"Rol\", \"puestoTrabajo\" AS \"PuestoTrabajo\", \"metodoContacto\" AS \"MetodoContacto\" FROM USUARIO;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<Usuario>(query);
    }

    public async Task<Usuario?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_usuario\" AS \"IdUsuario\", \"nombre\" AS \"Nombre\", \"rol\" AS \"Rol\", \"puestoTrabajo\" AS \"PuestoTrabajo\", \"metodoContacto\" AS \"MetodoContacto\" FROM USUARIO WHERE \"id_usuario\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Usuario>(query, new { Id = id });
    }

    public async Task<Usuario> CreateAsync(CreateUsuarioDto dto)
    {
        const string query = "INSERT INTO USUARIO (\"nombre\", \"rol\", \"puestoTrabajo\", \"metodoContacto\") VALUES (@Nombre, @Rol, @PuestoTrabajo, @MetodoContacto) RETURNING \"id_usuario\" AS \"IdUsuario\", \"nombre\" AS \"Nombre\", \"rol\" AS \"Rol\", \"puestoTrabajo\" AS \"PuestoTrabajo\", \"metodoContacto\" AS \"MetodoContacto\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<Usuario>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateUsuarioDto dto)
    {
        const string query = "UPDATE USUARIO SET \"nombre\" = @Nombre, \"rol\" = @Rol, \"puestoTrabajo\" = @PuestoTrabajo, \"metodoContacto\" = @MetodoContacto WHERE \"id_usuario\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM USUARIO WHERE \"id_usuario\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
