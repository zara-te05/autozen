using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IValeSalidaRepository
{
    Task<IEnumerable<ValeSalida>> GetAllAsync();
    Task<ValeSalida?> GetByIdAsync(int id);
    Task<ValeSalida> CreateAsync(CreateValeSalidaDto dto);
    Task<bool> UpdateAsync(int id, CreateValeSalidaDto dto);
    Task<bool> DeleteAsync(int id);
}

public class ValeSalidaRepository : IValeSalidaRepository
{
    private readonly DapperContext _context;

    public ValeSalidaRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<ValeSalida>> GetAllAsync()
    {
        const string query = "SELECT \"id_vale\" AS \"IdVale\", \"operacion_id\" AS \"OperacionId\", \"usuario_id\" AS \"UsuarioId\", \"entregadoA\" AS \"EntregadoA\", \"fechaEntrega\" AS \"FechaEntrega\" FROM VALE_SALIDA;";
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<ValeSalida>(query, transaction: tx));
    }

    public async Task<ValeSalida?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_vale\" AS \"IdVale\", \"operacion_id\" AS \"OperacionId\", \"usuario_id\" AS \"UsuarioId\", \"entregadoA\" AS \"EntregadoA\", \"fechaEntrega\" AS \"FechaEntrega\" FROM VALE_SALIDA WHERE \"id_vale\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<ValeSalida>(query, new { Id = id }, transaction: tx));
    }

    public async Task<ValeSalida> CreateAsync(CreateValeSalidaDto dto)
    {
        const string query = "INSERT INTO VALE_SALIDA (\"operacion_id\", \"usuario_id\", \"entregadoA\", \"fechaEntrega\") VALUES (@OperacionId, @UsuarioId, @EntregadoA, @FechaEntrega) RETURNING \"id_vale\" AS \"IdVale\", \"operacion_id\" AS \"OperacionId\", \"usuario_id\" AS \"UsuarioId\", \"entregadoA\" AS \"EntregadoA\", \"fechaEntrega\" AS \"FechaEntrega\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<ValeSalida>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateValeSalidaDto dto)
    {
        const string query = "UPDATE VALE_SALIDA SET \"operacion_id\" = @OperacionId, \"usuario_id\" = @UsuarioId, \"entregadoA\" = @EntregadoA, \"fechaEntrega\" = @FechaEntrega WHERE \"id_vale\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM VALE_SALIDA WHERE \"id_vale\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
