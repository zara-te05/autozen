using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IOperacionRepository
{
    Task<IEnumerable<Operacion>> GetAllAsync();
    Task<Operacion?> GetByIdAsync(int id);
    Task<Operacion> CreateAsync(CreateOperacionDto dto);
    Task<bool> UpdateAsync(int id, CreateOperacionDto dto);
    Task<bool> DeleteAsync(int id);
}

public class OperacionRepository : IOperacionRepository
{
    private readonly DapperContext _context;

    public OperacionRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Operacion>> GetAllAsync()
    {
        const string query = "SELECT \"id_operacion\" AS \"IdOperacion\", \"camion_id\" AS \"CamionId\", \"usuario_id\" AS \"UsuarioId\", \"fechaInicio\" AS \"FechaInicio\", \"fechaEstimadaFinalizacion\" AS \"FechaEstimadaFinalizacion\", \"estadoOperacion\" AS \"EstadoOperacion\" FROM OPERACIONES;";
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<Operacion>(query, transaction: tx));
    }

    public async Task<Operacion?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_operacion\" AS \"IdOperacion\", \"camion_id\" AS \"CamionId\", \"usuario_id\" AS \"UsuarioId\", \"fechaInicio\" AS \"FechaInicio\", \"fechaEstimadaFinalizacion\" AS \"FechaEstimadaFinalizacion\", \"estadoOperacion\" AS \"EstadoOperacion\" FROM OPERACIONES WHERE \"id_operacion\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<Operacion>(query, new { Id = id }, transaction: tx));
    }

    public async Task<Operacion> CreateAsync(CreateOperacionDto dto)
    {
        const string query = "INSERT INTO OPERACIONES (\"camion_id\", \"usuario_id\", \"fechaInicio\", \"fechaEstimadaFinalizacion\", \"estadoOperacion\") VALUES (@CamionId, @UsuarioId, @FechaInicio, @FechaEstimadaFinalizacion, @EstadoOperacion) RETURNING \"id_operacion\" AS \"IdOperacion\", \"camion_id\" AS \"CamionId\", \"usuario_id\" AS \"UsuarioId\", \"fechaInicio\" AS \"FechaInicio\", \"fechaEstimadaFinalizacion\" AS \"FechaEstimadaFinalizacion\", \"estadoOperacion\" AS \"EstadoOperacion\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<Operacion>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateOperacionDto dto)
    {
        const string query = "UPDATE OPERACIONES SET \"camion_id\" = @CamionId, \"usuario_id\" = @UsuarioId, \"fechaInicio\" = @FechaInicio, \"fechaEstimadaFinalizacion\" = @FechaEstimadaFinalizacion, \"estadoOperacion\" = @EstadoOperacion WHERE \"id_operacion\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM OPERACIONES WHERE \"id_operacion\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
