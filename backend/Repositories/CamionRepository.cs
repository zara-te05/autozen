using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface ICamionRepository
{
    Task<IEnumerable<Camion>> GetAllAsync();
    Task<Camion?> GetByIdAsync(int id);
    Task<Camion> CreateAsync(CreateCamionDto dto);
    Task<bool> UpdateAsync(int id, CreateCamionDto dto);
    Task<bool> DeleteAsync(int id);
}

public class CamionRepository : ICamionRepository
{
    private readonly DapperContext _context;

    public CamionRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Camion>> GetAllAsync()
    {
        const string query = "SELECT \"id_camion\" AS \"IdCamion\", \"cliente_id\" AS \"ClienteId\", \"placas\" AS \"Placas\", \"marca\" AS \"Marca\", \"modelo\" AS \"Modelo\", \"fechaEntrada\" AS \"FechaEntrada\", \"tiempoEsperado\" AS \"TiempoEsperado\" FROM CAMION;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<Camion>(query);
    }

    public async Task<Camion?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_camion\" AS \"IdCamion\", \"cliente_id\" AS \"ClienteId\", \"placas\" AS \"Placas\", \"marca\" AS \"Marca\", \"modelo\" AS \"Modelo\", \"fechaEntrada\" AS \"FechaEntrada\", \"tiempoEsperado\" AS \"TiempoEsperado\" FROM CAMION WHERE \"id_camion\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Camion>(query, new { Id = id });
    }

    public async Task<Camion> CreateAsync(CreateCamionDto dto)
    {
        const string query = "INSERT INTO CAMION (\"cliente_id\", \"placas\", \"marca\", \"modelo\", \"fechaEntrada\", \"tiempoEsperado\") VALUES (@ClienteId, @Placas, @Marca, @Modelo, @FechaEntrada, @TiempoEsperado) RETURNING \"id_camion\" AS \"IdCamion\", \"cliente_id\" AS \"ClienteId\", \"placas\" AS \"Placas\", \"marca\" AS \"Marca\", \"modelo\" AS \"Modelo\", \"fechaEntrada\" AS \"FechaEntrada\", \"tiempoEsperado\" AS \"TiempoEsperado\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<Camion>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateCamionDto dto)
    {
        const string query = "UPDATE CAMION SET \"cliente_id\" = @ClienteId, \"placas\" = @Placas, \"marca\" = @Marca, \"modelo\" = @Modelo, \"fechaEntrada\" = @FechaEntrada, \"tiempoEsperado\" = @TiempoEsperado WHERE \"id_camion\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM CAMION WHERE \"id_camion\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
