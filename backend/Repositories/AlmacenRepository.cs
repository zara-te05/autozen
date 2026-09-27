using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IAlmacenRepository
{
    Task<IEnumerable<Almacen>> GetAllAsync();
    Task<Almacen?> GetByIdAsync(int id);
    Task<Almacen> CreateAsync(CreateAlmacenDto dto);
    Task<bool> UpdateAsync(int id, CreateAlmacenDto dto);
    Task<bool> DeleteAsync(int id);
}

public class AlmacenRepository : IAlmacenRepository
{
    private readonly DapperContext _context;

    public AlmacenRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Almacen>> GetAllAsync()
    {
        const string query = "SELECT \"id_almacen\" AS \"IdAlmacen\", \"nombrePieza\" AS \"NombrePieza\", \"cantidadStock\" AS \"CantidadStock\", \"costoPiezas\" AS \"CostoPiezas\" FROM ALMACEN;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<Almacen>(query);
    }

    public async Task<Almacen?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_almacen\" AS \"IdAlmacen\", \"nombrePieza\" AS \"NombrePieza\", \"cantidadStock\" AS \"CantidadStock\", \"costoPiezas\" AS \"CostoPiezas\" FROM ALMACEN WHERE \"id_almacen\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<Almacen>(query, new { Id = id });
    }

    public async Task<Almacen> CreateAsync(CreateAlmacenDto dto)
    {
        const string query = "INSERT INTO ALMACEN (\"nombrePieza\", \"cantidadStock\", \"costoPiezas\") VALUES (@NombrePieza, @CantidadStock, @CostoPiezas) RETURNING \"id_almacen\" AS \"IdAlmacen\", \"nombrePieza\" AS \"NombrePieza\", \"cantidadStock\" AS \"CantidadStock\", \"costoPiezas\" AS \"CostoPiezas\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<Almacen>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateAlmacenDto dto)
    {
        const string query = "UPDATE ALMACEN SET \"nombrePieza\" = @NombrePieza, \"cantidadStock\" = @CantidadStock, \"costoPiezas\" = @CostoPiezas WHERE \"id_almacen\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM ALMACEN WHERE \"id_almacen\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
