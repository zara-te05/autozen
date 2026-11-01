using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Errors;
using Dapper;

namespace Autozen.Api.Services;

/// <summary>Préstamos de herramienta a proyectos. La herramienta sale del almacén y debe regresar.</summary>
public class HerramientasService
{
    private readonly DapperContext _db;
    private readonly AlmacenService _almacen;

    public HerramientasService(DapperContext db, AlmacenService almacen)
    {
        _db = db;
        _almacen = almacen;
    }

    private sealed class PrestamoRow
    {
        public int Id { get; set; }
        public int ProyectoId { get; set; }
        public string TipoProyecto { get; set; } = Codigos.Cliente;
        public string ProyectoNombre { get; set; } = string.Empty;
        public int? ArticuloId { get; set; }
        public string ArticuloNombre { get; set; } = string.Empty;
        public string Unidad { get; set; } = "pieza";
        public decimal Cantidad { get; set; }
        public string EntregadoA { get; set; } = string.Empty;
        public DateTime FechaSalida { get; set; }
        public DateTime? FechaDevolucion { get; set; }
        public string? EstadoDevolucion { get; set; }
    }

    private sealed class EstadoPrestamoRow
    {
        public int ProyectoId { get; set; }
        public int? AlmacenId { get; set; }
        public decimal Cantidad { get; set; }
        public DateTime? Devolucion { get; set; }
    }

    private Task<EstadoPrestamoRow?> BloquearPrestamoAsync(int id) => _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<EstadoPrestamoRow?>(
        "SELECT operacion_id AS ProyectoId, almacen_id AS AlmacenId, cantidad AS Cantidad, fecha_devolucion AS Devolucion FROM EQUIPO_ALMACEN WHERE id_equipo = @Id FOR UPDATE;",
        new { Id = id }, transaction: tx));

    public async Task<List<ValeHerramientaDto>> ListarAsync(int? proyectoId)
    {
        var filas = await _db.RunAsync((cn, tx) => cn.QueryAsync<PrestamoRow>(
            $@"SELECT e.id_equipo AS Id, e.operacion_id AS ProyectoId, o.tipo_proyecto AS TipoProyecto,
                      {Codigos.NombreCamionSql} || ' (' || c.placas || ')' AS ProyectoNombre,
                      e.almacen_id AS ArticuloId, COALESCE(a.""nombrePieza"", e.""nombreHerramienta"") AS ArticuloNombre,
                      COALESCE(a.unidad_medida, 'pieza') AS Unidad, e.cantidad AS Cantidad, COALESCE(e.entregado_a, '') AS EntregadoA,
                      COALESCE(e.fecha_salida, now()) AS FechaSalida, e.fecha_devolucion AS FechaDevolucion, e.estado_devolucion AS EstadoDevolucion
               FROM EQUIPO_ALMACEN e
               JOIN OPERACIONES o ON o.id_operacion = e.operacion_id
               JOIN CAMION c ON c.id_camion = o.camion_id
               LEFT JOIN ALMACEN a ON a.id_almacen = e.almacen_id
               WHERE (@ProyectoId::int IS NULL OR e.operacion_id = @ProyectoId)
               ORDER BY e.id_equipo DESC;",
            new { ProyectoId = proyectoId }, transaction: tx));

        return filas.Select(p => new ValeHerramientaDto
        {
            Id = p.Id,
            Codigo = Codigos.ValeHerramienta(p.Id),
            ProyectoId = p.ProyectoId,
            ProyectoCodigo = Codigos.Proyecto(p.TipoProyecto, p.ProyectoId),
            ProyectoNombre = p.ProyectoNombre,
            ArticuloId = p.ArticuloId,
            ArticuloNombre = p.ArticuloNombre,
            Unidad = p.Unidad,
            Cantidad = p.Cantidad,
            EntregadoA = p.EntregadoA,
            FechaSalida = p.FechaSalida,
            FechaDevolucion = p.FechaDevolucion,
            EstadoDevolucion = p.EstadoDevolucion,
        }).ToList();
    }

    public async Task<ValeHerramientaDto> PrestarAsync(PrestarHerramientaRequest r)
    {
        int id = await _db.EnTransaccionAsync(async () =>
        {
            var articulo = await _almacen.BloquearArticuloAsync(r.ArticuloId);
            if (articulo.Tipo != AlmacenService.Herramienta)
                throw new ReglaNegocioException($"\"{articulo.Nombre}\" es un material: usa el vale de material.");
            if (string.IsNullOrWhiteSpace(r.EntregadoA))
                throw new ReglaNegocioException("Indica quién se hace responsable de la herramienta.");
            AlmacenService.ValidarDecimales(articulo.Unidad, r.Cantidad, "La cantidad");
            await _almacen.ValidarProyectoActivoAsync(r.ProyectoId);
            await _almacen.DescontarAsync(articulo, r.Cantidad);

            return await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<int>(
                @"INSERT INTO EQUIPO_ALMACEN (operacion_id, ""nombreHerramienta"", ""estadoSalida"", ""estadoDevuelto"",
                                              almacen_id, cantidad, entregado_a, fecha_salida)
                  VALUES (@ProyectoId, @Nombre, 'Operativa', 'En Uso', @ArticuloId, @Cantidad, @EntregadoA, @Fecha)
                  RETURNING id_equipo;",
                new { r.ProyectoId, Nombre = articulo.Nombre, r.ArticuloId, r.Cantidad, EntregadoA = r.EntregadoA.Trim(), Fecha = DateTime.Now },
                transaction: tx));
        });

        return (await ListarAsync(r.ProyectoId)).First(p => p.Id == id);
    }

    public async Task<ValeHerramientaDto> DevolverAsync(int id, string estado)
    {
        var limpio = string.IsNullOrWhiteSpace(estado) ? "Buen estado" : estado.Trim();
        int proyectoId = await _db.EnTransaccionAsync(async () =>
        {
            var prestamo = await BloquearPrestamoAsync(id) ?? throw new NoEncontradoException("El préstamo no existe.");
            if (prestamo.Devolucion is not null) throw new ConflictoException("Esta herramienta ya fue devuelta.");

            await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                @"UPDATE EQUIPO_ALMACEN SET fecha_devolucion = @Fecha, estado_devolucion = @Estado, ""estadoDevuelto"" = @Estado WHERE id_equipo = @Id;",
                new { Id = id, Estado = limpio, Fecha = DateTime.Now }, transaction: tx));
            if (prestamo.AlmacenId is not null)
            {
                await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                    @"UPDATE ALMACEN SET ""cantidadStock"" = COALESCE(""cantidadStock"", 0) + @Cantidad WHERE id_almacen = @AlmacenId;",
                    new { prestamo.AlmacenId, prestamo.Cantidad }, transaction: tx));
            }
            return prestamo.ProyectoId;
        });

        return (await ListarAsync(proyectoId)).First(p => p.Id == id);
    }

    /// <summary>Elimina el registro. Si la herramienta seguía prestada, regresa al almacén.</summary>
    public async Task EliminarAsync(int id)
    {
        await _db.EnTransaccionAsync(async () =>
        {
            var prestamo = await BloquearPrestamoAsync(id) ?? throw new NoEncontradoException("El préstamo no existe.");

            if (prestamo.Devolucion is null && prestamo.AlmacenId is not null)
            {
                await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                    @"UPDATE ALMACEN SET ""cantidadStock"" = COALESCE(""cantidadStock"", 0) + @Cantidad WHERE id_almacen = @AlmacenId;",
                    new { prestamo.AlmacenId, prestamo.Cantidad }, transaction: tx));
            }
            await _db.RunAsync((cn, tx) => cn.ExecuteAsync("DELETE FROM EQUIPO_ALMACEN WHERE id_equipo = @Id;", new { Id = id }, transaction: tx));
            return true;
        });
    }
}
