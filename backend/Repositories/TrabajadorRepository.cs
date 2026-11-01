using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface ITrabajadorRepository
{
    Task<IEnumerable<Trabajador>> GetAllAsync();
    Task<Trabajador?> GetByIdAsync(int id);
    Task<Trabajador> CreateAsync(CreateTrabajadorDto dto);
    Task<bool> UpdateAsync(int id, CreateTrabajadorDto dto);
    Task<bool> DeleteAsync(int id);
}

public class TrabajadorRepository : ITrabajadorRepository
{
    private readonly DapperContext _context;

    public TrabajadorRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Trabajador>> GetAllAsync()
    {
        const string query = "SELECT \"id_trabajador\" AS \"IdTrabajador\", \"nombreTrabajador\" AS \"NombreTrabajador\", \"apellidoTrabajador\" AS \"ApellidoTrabajador\", \"salarioTrabajador\" AS \"SalarioTrabajador\" FROM TRABAJADOR;";
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<Trabajador>(query, transaction: tx));
    }

    public async Task<Trabajador?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_trabajador\" AS \"IdTrabajador\", \"nombreTrabajador\" AS \"NombreTrabajador\", \"apellidoTrabajador\" AS \"ApellidoTrabajador\", \"salarioTrabajador\" AS \"SalarioTrabajador\" FROM TRABAJADOR WHERE \"id_trabajador\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<Trabajador>(query, new { Id = id }, transaction: tx));
    }

    public async Task<Trabajador> CreateAsync(CreateTrabajadorDto dto)
    {
        const string query = "INSERT INTO TRABAJADOR (\"nombreTrabajador\", \"apellidoTrabajador\", \"salarioTrabajador\") VALUES (@NombreTrabajador, @ApellidoTrabajador, @SalarioTrabajador) RETURNING \"id_trabajador\" AS \"IdTrabajador\", \"nombreTrabajador\" AS \"NombreTrabajador\", \"apellidoTrabajador\" AS \"ApellidoTrabajador\", \"salarioTrabajador\" AS \"SalarioTrabajador\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<Trabajador>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateTrabajadorDto dto)
    {
        const string query = "UPDATE TRABAJADOR SET \"nombreTrabajador\" = @NombreTrabajador, \"apellidoTrabajador\" = @ApellidoTrabajador, \"salarioTrabajador\" = @SalarioTrabajador WHERE \"id_trabajador\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM TRABAJADOR WHERE \"id_trabajador\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
