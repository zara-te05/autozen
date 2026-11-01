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
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<Almacen>(query, transaction: tx));
    }

    public async Task<Almacen?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_almacen\" AS \"IdAlmacen\", \"nombrePieza\" AS \"NombrePieza\", \"cantidadStock\" AS \"CantidadStock\", \"costoPiezas\" AS \"CostoPiezas\" FROM ALMACEN WHERE \"id_almacen\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<Almacen>(query, new { Id = id }, transaction: tx));
    }

    public async Task<Almacen> CreateAsync(CreateAlmacenDto dto)
    {
        const string query = "INSERT INTO ALMACEN (\"nombrePieza\", \"cantidadStock\", \"costoPiezas\") VALUES (@NombrePieza, @CantidadStock, @CostoPiezas) RETURNING \"id_almacen\" AS \"IdAlmacen\", \"nombrePieza\" AS \"NombrePieza\", \"cantidadStock\" AS \"CantidadStock\", \"costoPiezas\" AS \"CostoPiezas\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<Almacen>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateAlmacenDto dto)
    {
        const string query = "UPDATE ALMACEN SET \"nombrePieza\" = @NombrePieza, \"cantidadStock\" = @CantidadStock, \"costoPiezas\" = @CostoPiezas WHERE \"id_almacen\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM ALMACEN WHERE \"id_almacen\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
