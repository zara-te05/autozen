using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Errors;
using Dapper;

namespace Autozen.Api.Services;

/// <summary>
/// Tablero de inicio del dashboard: entregas de unidades de la semana, coordinación operativa
/// del día (post-its de cuadrillas) y anuncios. Todo se captura a mano por el Admin.
/// Las fechas se calculan en la zona horaria del taller (Ciudad de México) dentro de PostgreSQL,
/// así no dependen de la zona del servidor ni del contenedor.
/// </summary>
public class TableroService
{
    private const string Zona = "America/Mexico_City";
    private const string HoraCorte = "19"; // 7 pm: se borra la coordinación del día

    /// <summary>Lunes de la semana actual (fecha local del taller).</summary>
    private const string InicioSemanaSql = $"date_trunc('week', now() AT TIME ZONE '{Zona}')::date";

    /// <summary>Último corte de las 7 pm ya pasado, como instante (timestamptz).</summary>
    private const string UltimoCorteSql =
        $"((date_trunc('day', (now() AT TIME ZONE '{Zona}') - interval '{HoraCorte} hours') + interval '{HoraCorte} hours') AT TIME ZONE '{Zona}')";

    private static readonly string[] Colores = ["amarillo", "rosa", "azul", "verde", "naranja"];

    private const string SelectEntrega =
        "SELECT id_entrega AS Id, unidad AS Unidad, cliente AS Cliente, fecha_entrega AS FechaEntrega, notas AS Notas, " +
        "entregada AS Entregada, creado_por AS CreadoPor FROM TABLERO_ENTREGA";
    private const string ReturningEntrega =
        " RETURNING id_entrega AS Id, unidad AS Unidad, cliente AS Cliente, fecha_entrega AS FechaEntrega, notas AS Notas, " +
        "entregada AS Entregada, creado_por AS CreadoPor;";

    private const string SelectCoordinacion =
        "SELECT id_coordinacion AS Id, cuadrilla AS Cuadrilla, asignacion AS Asignacion, color AS Color, " +
        "creado_por AS CreadoPor, creado AS Creado FROM TABLERO_COORDINACION";
    private const string ReturningCoordinacion =
        " RETURNING id_coordinacion AS Id, cuadrilla AS Cuadrilla, asignacion AS Asignacion, color AS Color, " +
        "creado_por AS CreadoPor, creado AS Creado;";

    private const string SelectAnuncio =
        "SELECT id_anuncio AS Id, titulo AS Titulo, contenido AS Contenido, creado_por AS CreadoPor, " +
        "creado AS Creado, editado AS Editado FROM TABLERO_ANUNCIO";
    private const string ReturningAnuncio =
        " RETURNING id_anuncio AS Id, titulo AS Titulo, contenido AS Contenido, creado_por AS CreadoPor, " +
        "creado AS Creado, editado AS Editado;";

    private readonly DapperContext _db;

    public TableroService(DapperContext db) => _db = db;

    // ------------------------------------------------------------------
    // Tablero completo
    // ------------------------------------------------------------------

    public async Task<TableroDto> ObtenerAsync()
    {
        await BorrarCoordinacionVencidaAsync();

        var semana = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<(DateTime Inicio, DateTime Fin)>(
            $"SELECT {InicioSemanaSql} AS Inicio, {InicioSemanaSql} + 6 AS Fin;", transaction: tx));

        var entregas = await _db.RunAsync((cn, tx) => cn.QueryAsync<EntregaSemanaDto>(
            $"{SelectEntrega} WHERE fecha_entrega BETWEEN {InicioSemanaSql} AND {InicioSemanaSql} + 6 " +
            "ORDER BY fecha_entrega, entregada, lower(unidad);", transaction: tx));

        var coordinacion = await _db.RunAsync((cn, tx) => cn.QueryAsync<CoordinacionDto>(
            $"{SelectCoordinacion} ORDER BY creado;", transaction: tx));

        var anuncios = await _db.RunAsync((cn, tx) => cn.QueryAsync<AnuncioDto>(
            $"{SelectAnuncio} ORDER BY creado DESC LIMIT 50;", transaction: tx));

        return new TableroDto
        {
            InicioSemana = semana.Inicio,
            FinSemana = semana.Fin,
            Entregas = entregas.ToList(),
            Coordinacion = coordinacion.ToList(),
            Anuncios = anuncios.ToList(),
        };
    }

    // ------------------------------------------------------------------
    // Entregas de la semana
    // ------------------------------------------------------------------

    public async Task<EntregaSemanaDto> GuardarEntregaAsync(int? id, EntregaSemanaDto d, string? usuario)
    {
        var p = new
        {
            Id = id,
            Unidad = d.Unidad.Trim(),
            Cliente = Limpiar(d.Cliente),
            FechaEntrega = (d.FechaEntrega ?? throw new ReglaNegocioException("La fecha de entrega es obligatoria.")).Date,
            Notas = Limpiar(d.Notas),
            d.Entregada,
            Usuario = usuario,
        };
        if (p.Unidad.Length == 0) throw new ReglaNegocioException("La unidad es obligatoria.");

        var resultado = id is null
            ? await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<EntregaSemanaDto>(
                "INSERT INTO TABLERO_ENTREGA (unidad, cliente, fecha_entrega, notas, entregada, creado_por) " +
                "VALUES (@Unidad, @Cliente, @FechaEntrega, @Notas, @Entregada, @Usuario)" + ReturningEntrega, p, transaction: tx))
            : await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<EntregaSemanaDto>(
                "UPDATE TABLERO_ENTREGA SET unidad = @Unidad, cliente = @Cliente, fecha_entrega = @FechaEntrega, " +
                "notas = @Notas, entregada = @Entregada WHERE id_entrega = @Id" + ReturningEntrega, p, transaction: tx));
        return resultado ?? throw new NoEncontradoException("La entrega no existe.");
    }

    public Task EliminarEntregaAsync(int id) =>
        EliminarAsync("DELETE FROM TABLERO_ENTREGA WHERE id_entrega = @Id;", id, "La entrega no existe.");

    // ------------------------------------------------------------------
    // Coordinación operativa del día
    // ------------------------------------------------------------------

    public async Task<CoordinacionDto> GuardarCoordinacionAsync(int? id, CoordinacionDto d, string? usuario)
    {
        await BorrarCoordinacionVencidaAsync();

        var color = d.Color?.Trim().ToLowerInvariant();
        var p = new
        {
            Id = id,
            Cuadrilla = d.Cuadrilla.Trim(),
            Asignacion = d.Asignacion.Trim(),
            Color = color is not null && Colores.Contains(color) ? color : Colores[0],
            Usuario = usuario,
        };
        if (p.Cuadrilla.Length == 0) throw new ReglaNegocioException("La cuadrilla es obligatoria.");
        if (p.Asignacion.Length == 0) throw new ReglaNegocioException("La asignación es obligatoria.");

        var resultado = id is null
            ? await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<CoordinacionDto>(
                "INSERT INTO TABLERO_COORDINACION (cuadrilla, asignacion, color, creado_por) " +
                "VALUES (@Cuadrilla, @Asignacion, @Color, @Usuario)" + ReturningCoordinacion, p, transaction: tx))
            : await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<CoordinacionDto>(
                "UPDATE TABLERO_COORDINACION SET cuadrilla = @Cuadrilla, asignacion = @Asignacion, color = @Color " +
                "WHERE id_coordinacion = @Id" + ReturningCoordinacion, p, transaction: tx));
        return resultado ?? throw new NoEncontradoException("La nota ya no existe (se borran a las 7 pm).");
    }

    public Task EliminarCoordinacionAsync(int id) =>
        EliminarAsync("DELETE FROM TABLERO_COORDINACION WHERE id_coordinacion = @Id;", id, "La nota ya no existe.");

    /// <summary>
    /// Borra las notas creadas antes del último corte de las 7 pm. Se ejecuta al leer y al escribir,
    /// y además cada día a las 7 pm desde <see cref="LimpiezaCoordinacionService"/>.
    /// </summary>
    public Task<int> BorrarCoordinacionVencidaAsync() =>
        _db.RunAsync((cn, tx) => cn.ExecuteAsync(
            $"DELETE FROM TABLERO_COORDINACION WHERE creado < {UltimoCorteSql};", transaction: tx));

    // ------------------------------------------------------------------
    // Anuncios
    // ------------------------------------------------------------------

    public async Task<AnuncioDto> GuardarAnuncioAsync(int? id, AnuncioDto d, string? usuario)
    {
        var p = new { Id = id, Titulo = d.Titulo.Trim(), Contenido = d.Contenido.Trim(), Usuario = usuario };
        if (p.Titulo.Length == 0) throw new ReglaNegocioException("El título es obligatorio.");
        if (p.Contenido.Length == 0) throw new ReglaNegocioException("El contenido es obligatorio.");

        var resultado = id is null
            ? await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<AnuncioDto>(
                "INSERT INTO TABLERO_ANUNCIO (titulo, contenido, creado_por) VALUES (@Titulo, @Contenido, @Usuario)" + ReturningAnuncio,
                p, transaction: tx))
            : await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<AnuncioDto>(
                "UPDATE TABLERO_ANUNCIO SET titulo = @Titulo, contenido = @Contenido, editado = now() WHERE id_anuncio = @Id" + ReturningAnuncio,
                p, transaction: tx));
        return resultado ?? throw new NoEncontradoException("El anuncio no existe.");
    }

    public Task EliminarAnuncioAsync(int id) =>
        EliminarAsync("DELETE FROM TABLERO_ANUNCIO WHERE id_anuncio = @Id;", id, "El anuncio no existe.");

    // ------------------------------------------------------------------

    private async Task EliminarAsync(string sql, int id, string mensajeNoEncontrado)
    {
        var filas = await _db.RunAsync((cn, tx) => cn.ExecuteAsync(sql, new { Id = id }, transaction: tx));
        if (filas == 0) throw new NoEncontradoException(mensajeNoEncontrado);
    }

    private static string? Limpiar(string? texto) => string.IsNullOrWhiteSpace(texto) ? null : texto.Trim();
}
