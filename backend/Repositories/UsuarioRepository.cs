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
    Task<Usuario?> GetByUsername(string username);
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
        const string query = "SELECT \"id_usuario\" AS \"IdUsuario\", \"trabajador_id\" AS \"TrabajadorId\", \"nombre\" AS \"Nombre\", \"username\" AS \"Username\", \"rol\" AS \"Rol\", \"puestoTrabajo\" AS \"PuestoTrabajo\", \"metodoContacto\" AS \"MetodoContacto\", \"area\" AS \"Area\" FROM USUARIO;";
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<Usuario>(query, transaction: tx));
    }

    public async Task<Usuario?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_usuario\" AS \"IdUsuario\", \"trabajador_id\" AS \"TrabajadorId\", \"nombre\" AS \"Nombre\", \"username\" AS \"Username\", \"rol\" AS \"Rol\", \"password\" AS \"Password\", \"puestoTrabajo\" AS \"PuestoTrabajo\", \"metodoContacto\" AS \"MetodoContacto\", \"area\" AS \"Area\" FROM USUARIO WHERE \"id_usuario\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<Usuario>(query, new { Id = id }, transaction: tx));
    }

    public async Task<Usuario?> GetByUsername(string username)
    {
        const string query = "SELECT \"id_usuario\" AS \"IdUsuario\", \"trabajador_id\" AS \"TrabajadorId\", \"nombre\" AS \"Nombre\", \"username\" AS \"Username\", \"password\" AS \"Password\", \"rol\" AS \"Rol\", \"puestoTrabajo\" AS \"PuestoTrabajo\", \"metodoContacto\" AS \"MetodoContacto\", \"area\" AS \"Area\" FROM USUARIO WHERE \"username\" = @Username;";

        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<Usuario>(query, new { Username = username }, transaction: tx));
    }

    public async Task<Usuario> CreateAsync(CreateUsuarioDto dto)
    {
        const string query = "INSERT INTO USUARIO (\"trabajador_id\", \"nombre\", \"username\", \"rol\", \"password\", \"puestoTrabajo\", \"metodoContacto\", \"area\") " +
                             "VALUES (@TrabajadorId, @Nombre, @Username, @Rol, @Password, @PuestoTrabajo, @MetodoContacto, @Area) " +
                             "RETURNING \"id_usuario\" AS \"IdUsuario\", \"trabajador_id\" AS \"TrabajadorId\", \"nombre\" AS \"Nombre\", \"username\" AS \"Username\", \"rol\" AS \"Rol\", \"puestoTrabajo\" AS \"PuestoTrabajo\", \"metodoContacto\" AS \"MetodoContacto\", \"area\" AS \"Area\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<Usuario>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateUsuarioDto dto)
    {
        const string query = "UPDATE USUARIO SET \"trabajador_id\" = @TrabajadorId, \"nombre\" = @Nombre, \"username\" = @Username, \"rol\" = @Rol, \"password\" = @Password, \"puestoTrabajo\" = @PuestoTrabajo, \"metodoContacto\" = @MetodoContacto, \"area\" = @Area WHERE \"id_usuario\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM USUARIO WHERE \"id_usuario\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}