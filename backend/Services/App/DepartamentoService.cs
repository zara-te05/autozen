using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Errors;
using Dapper;

namespace Autozen.Api.Services;

public class DepartamentoService
{
    private readonly DapperContext _db;

    public DepartamentoService(DapperContext db) => _db = db;

    private const string Select = "SELECT id_departamento AS Id, nombre AS Nombre, encargado AS Encargado, icono AS Icono, personal AS Personal FROM DEPARTAMENTO";

    public async Task<List<DepartamentoDto>> ListarAsync() =>
        (await _db.RunAsync((cn, tx) => cn.QueryAsync<DepartamentoDto>(Select + " ORDER BY lower(nombre);", transaction: tx))).ToList();

    public async Task<DepartamentoDto> GuardarAsync(int? id, DepartamentoDto d)
    {
        var parametros = new { Id = id, Nombre = d.Nombre.Trim(), Encargado = d.Encargado?.Trim(), Icono = string.IsNullOrWhiteSpace(d.Icono) ? "business" : d.Icono.Trim(), d.Personal };
        if (parametros.Nombre.Length == 0) throw new ReglaNegocioException("El nombre es obligatorio.");

        var resultado = id is null
            ? await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<DepartamentoDto>(
                "INSERT INTO DEPARTAMENTO (nombre, encargado, icono, personal) VALUES (@Nombre, @Encargado, @Icono, @Personal) " +
                "RETURNING id_departamento AS Id, nombre AS Nombre, encargado AS Encargado, icono AS Icono, personal AS Personal;", parametros, transaction: tx))
            : await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<DepartamentoDto>(
                "UPDATE DEPARTAMENTO SET nombre = @Nombre, encargado = @Encargado, icono = @Icono, personal = @Personal WHERE id_departamento = @Id " +
                "RETURNING id_departamento AS Id, nombre AS Nombre, encargado AS Encargado, icono AS Icono, personal AS Personal;", parametros, transaction: tx));
        return resultado ?? throw new NoEncontradoException("El departamento no existe.");
    }

    public async Task EliminarAsync(int id)
    {
        var filas = await _db.RunAsync((cn, tx) => cn.ExecuteAsync("DELETE FROM DEPARTAMENTO WHERE id_departamento = @Id;", new { Id = id }, transaction: tx));
        if (filas == 0) throw new NoEncontradoException("El departamento no existe.");
    }
}
