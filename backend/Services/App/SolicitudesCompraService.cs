using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Errors;
using Dapper;

namespace Autozen.Api.Services;

/// <summary>
/// Flujo de compras de la app: un proyecto solicita lo que necesita → Compras llena la orden de compra
/// (proveedor, entrega, condiciones, partidas, IVA) y la aprueba, o la rechaza con un motivo.
/// </summary>
public class SolicitudesCompraService
{
    private readonly DapperContext _db;
    private readonly NotificacionService _avisos;

    public SolicitudesCompraService(DapperContext db, NotificacionService avisos)
    {
        _db = db;
        _avisos = avisos;
    }

    private sealed class SolicitudRow
    {
        public int Id { get; set; }
        public int ProyectoId { get; set; }
        public string TipoProyecto { get; set; } = Codigos.Cliente;
        public string ProyectoNombre { get; set; } = string.Empty;
        public string? SolicitadoPor { get; set; }
        public DateTime Fecha { get; set; }
        public string? Descripcion { get; set; }
        public decimal Cantidad { get; set; }
        public string Unidad { get; set; } = "Pieza";
        public string? Notas { get; set; }
        public string Estado { get; set; } = "Pendiente";
        public string? MotivoRechazo { get; set; }
        // Orden (si existe)
        public int? CompraId { get; set; }
        public string? Folio { get; set; }
        public DateTime? FechaOrden { get; set; }
        public int? ProveedorId { get; set; }
        public string? ProveedorNombre { get; set; }
        public string? ProveedorDireccion { get; set; }
        public string? Consignatario { get; set; }
        public DateTime? Entrega { get; set; }
        public string? Condiciones { get; set; }
        public string? ViaEmbarque { get; set; }
        public decimal? TasaIva { get; set; }
        public string? Observaciones { get; set; }
    }

    private sealed class PartidaRow
    {
        public int CompraId { get; set; }
        public string? Articulo { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string Unidad { get; set; } = "Pieza";
        public decimal Unidades { get; set; }
        public decimal Precio { get; set; }
        public decimal Descuento { get; set; }
    }

    public async Task<List<SolicitudCompraAppDto>> ListarAsync()
    {
        var filas = (await _db.RunAsync((cn, tx) => cn.QueryAsync<SolicitudRow>(
            $@"SELECT sc.id_solicitud_compra AS Id, sc.operacion_id AS ProyectoId, o.tipo_proyecto AS TipoProyecto,
                      {Codigos.NombreCamionSql} || ' (' || c.placas || ')' AS ProyectoNombre,
                      COALESCE(sc.solicitado_por, u.nombre) AS SolicitadoPor, sc.""fechaSolicitud"" AS Fecha,
                      sc.""nombrePiezasCotizadas"" AS Descripcion, COALESCE(sc.""cantidadPiezasCotizadas"", 1) AS Cantidad,
                      sc.unidad AS Unidad, sc.notas AS Notas, sc.estado AS Estado, sc.motivo_rechazo AS MotivoRechazo,
                      co.id_compra AS CompraId, COALESCE(co.folio, 'OC' || LPAD(co.id_compra::text, 5, '0')) AS Folio,
                      COALESCE(co.fecha, sc.""fechaSolicitud""::date) AS FechaOrden,
                      p.id_proveedor AS ProveedorId, p.""nombreProveedor"" AS ProveedorNombre, p.direccion AS ProveedorDireccion,
                      co.consignatario AS Consignatario, co.fecha_entrega AS Entrega, co.condiciones AS Condiciones,
                      co.via_embarque AS ViaEmbarque, co.tasa_iva AS TasaIva, co.observaciones AS Observaciones
               FROM SOLICITUD_COMPRA sc
               JOIN OPERACIONES o ON o.id_operacion = sc.operacion_id
               JOIN CAMION c ON c.id_camion = o.camion_id
               LEFT JOIN USUARIO u ON u.id_usuario = sc.usuario_id
               LEFT JOIN COMPRA co ON co.solicitud_compra_id = sc.id_solicitud_compra
               LEFT JOIN PROVEEDOR p ON p.id_proveedor = sc.proveedor_id
               ORDER BY sc.id_solicitud_compra DESC;", transaction: tx))).ToList();

        var compras = filas.Where(f => f.CompraId is not null).Select(f => f.CompraId!.Value).ToArray();
        var partidas = compras.Length == 0
            ? new List<PartidaRow>()
            : (await _db.RunAsync((cn, tx) => cn.QueryAsync<PartidaRow>(
                @"SELECT compra_id AS CompraId, articulo AS Articulo, nombre AS Nombre, unidad AS Unidad,
                         unidades AS Unidades, precio AS Precio, descuento AS Descuento
                  FROM COMPRA_PARTIDA WHERE compra_id = ANY(@Ids) ORDER BY compra_id, orden;",
                new { Ids = compras }, transaction: tx))).ToList();
        var partidasPor = partidas.ToLookup(p => p.CompraId);

        return filas.Select(f => new SolicitudCompraAppDto
        {
            Id = f.Id,
            ProyectoId = f.ProyectoId,
            ProyectoCodigo = Codigos.Proyecto(f.TipoProyecto, f.ProyectoId),
            ProyectoNombre = f.ProyectoNombre,
            SolicitadoPor = f.SolicitadoPor ?? string.Empty,
            Fecha = f.Fecha,
            Descripcion = f.Descripcion ?? string.Empty,
            Cantidad = f.Cantidad,
            Unidad = f.Unidad,
            Notas = f.Notas ?? string.Empty,
            Estado = f.Estado,
            MotivoRechazo = f.MotivoRechazo,
            Orden = f.CompraId is null ? null : new OrdenCompraDocDto
            {
                Folio = f.Folio ?? string.Empty,
                Fecha = f.FechaOrden ?? f.Fecha,
                ProveedorId = f.ProveedorId,
                ProveedorNombre = f.ProveedorNombre ?? string.Empty,
                ProveedorDireccion = f.ProveedorDireccion ?? string.Empty,
                Consignatario = f.Consignatario ?? string.Empty,
                Entrega = f.Entrega ?? f.FechaOrden ?? f.Fecha,
                Condiciones = f.Condiciones ?? "Contado",
                ViaEmbarque = f.ViaEmbarque ?? string.Empty,
                TasaIva = f.TasaIva ?? 0.16m,
                Observaciones = f.Observaciones ?? string.Empty,
                Partidas = partidasPor[f.CompraId.Value].Select(p => new PartidaOrdenDto
                {
                    Articulo = p.Articulo,
                    Nombre = p.Nombre,
                    Unidad = p.Unidad,
                    Unidades = p.Unidades,
                    Precio = p.Precio,
                    Descuento = p.Descuento,
                }).ToList(),
            },
        }).ToList();
    }

    private async Task<SolicitudCompraAppDto> ObtenerAsync(int id) =>
        (await ListarAsync()).FirstOrDefault(s => s.Id == id) ?? throw new NoEncontradoException("La solicitud no existe.");

    public async Task<SolicitudCompraAppDto> CrearAsync(CrearSolicitudAppRequest r, int? usuarioId, string? nombreUsuario)
    {
        var archivado = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<bool?>(
            "SELECT archivado FROM OPERACIONES WHERE id_operacion = @Id;", new { Id = r.ProyectoId }, transaction: tx));
        if (archivado is null) throw new NoEncontradoException("El proyecto no existe.");
        if (archivado.Value) throw new ConflictoException("El proyecto está archivado.");
        if (string.IsNullOrWhiteSpace(r.Descripcion)) throw new ReglaNegocioException("Escribe qué se necesita.");

        int id = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<int>(
            @"INSERT INTO SOLICITUD_COMPRA (operacion_id, usuario_id, ""nombrePiezasCotizadas"", ""cantidadPiezasCotizadas"", ""fechaSolicitud"",
                                            estado, unidad, notas, solicitado_por)
              VALUES (@ProyectoId, @UsuarioId, @Descripcion, @Cantidad, @Fecha, 'Pendiente', @Unidad, @Notas, @SolicitadoPor)
              RETURNING id_solicitud_compra;",
            new
            {
                r.ProyectoId,
                UsuarioId = usuarioId,
                Descripcion = r.Descripcion.Trim(),
                r.Cantidad,
                Fecha = DateTime.Now,
                Unidad = string.IsNullOrWhiteSpace(r.Unidad) ? "Pieza" : r.Unidad.Trim(),
                Notas = r.Notas?.Trim(),
                SolicitadoPor = nombreUsuario,
            }, transaction: tx));

        var creada = await ObtenerAsync(id);
        await _avisos.RegistrarAsync("compra_solicitada", "Nueva solicitud de compra",
            $"{creada.ProyectoNombre}: {creada.Descripcion} ({creada.Cantidad:0.###} {creada.Unidad})",
            Roles.Admin, Roles.ComprasAdmin);
        return creada;
    }

    public async Task<SolicitudCompraAppDto> AprobarAsync(int id, AprobarSolicitudRequest r)
    {
        var solicitud = await ObtenerAsync(id);
        if (solicitud.Estado != "Pendiente") throw new ConflictoException("La solicitud ya fue atendida.");
        if (r.Partidas.Count == 0) throw new ReglaNegocioException("Agrega al menos un artículo.");
        if (r.Partidas.Any(p => string.IsNullOrWhiteSpace(p.Nombre) || p.Unidades <= 0 || p.Precio < 0 || p.Descuento < 0))
            throw new ReglaNegocioException("Revisa los artículos: nombre, unidades y precio son obligatorios y no pueden ser negativos.");

        bool proveedorExiste = await _db.RunAsync((cn, tx) => cn.ExecuteScalarAsync<bool>(
            "SELECT EXISTS (SELECT 1 FROM PROVEEDOR WHERE id_proveedor = @Id);", new { Id = r.ProveedorId }, transaction: tx));
        if (!proveedorExiste) throw new ReglaNegocioException("El proveedor no existe.");

        decimal subtotal = r.Partidas.Sum(p => Math.Max(0, p.Unidades * p.Precio - p.Descuento));
        decimal total = Math.Round(subtotal + Math.Round(subtotal * r.TasaIva, 2), 2);
        var fecha = (r.Fecha ?? DateTime.Now).Date;

        await _db.EnTransaccionAsync(async () =>
        {
            int compraId = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<int>(
                @"INSERT INTO COMPRA (solicitud_compra_id, operacion_id, ""nombrePiezas"", ""cantidadPiezas"", ""costoPiezas"",
                                      fecha, fecha_entrega, condiciones, via_embarque, consignatario, tasa_iva, observaciones)
                  VALUES (@SolicitudId, @ProyectoId, @Nombre, @Cantidad, @Total, @Fecha, @Entrega, @Condiciones, @Via, @Consignatario, @TasaIva, @Observaciones)
                  RETURNING id_compra;",
                new
                {
                    SolicitudId = id,
                    solicitud.ProyectoId,
                    Nombre = string.Join(", ", r.Partidas.Select(p => p.Nombre.Trim())),
                    Cantidad = (int)Math.Max(1, Math.Ceiling(r.Partidas.Sum(p => p.Unidades))),
                    Total = total,
                    Fecha = fecha,
                    Entrega = r.Entrega.Date,
                    r.Condiciones,
                    Via = r.ViaEmbarque?.Trim(),
                    Consignatario = r.Consignatario?.Trim(),
                    r.TasaIva,
                    Observaciones = r.Observaciones?.Trim(),
                }, transaction: tx));

            await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                "UPDATE COMPRA SET folio = 'OC' || LPAD((16336 + id_compra)::text, 5, '0') WHERE id_compra = @Id;", new { Id = compraId }, transaction: tx));

            for (int i = 0; i < r.Partidas.Count; i++)
            {
                var p = r.Partidas[i];
                await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                    @"INSERT INTO COMPRA_PARTIDA (compra_id, orden, articulo, nombre, unidad, unidades, precio, descuento)
                      VALUES (@CompraId, @Orden, @Articulo, @Nombre, @Unidad, @Unidades, @Precio, @Descuento);",
                    new { CompraId = compraId, Orden = i, Articulo = p.Articulo?.Trim(), Nombre = p.Nombre.Trim(), Unidad = p.Unidad, p.Unidades, p.Precio, p.Descuento },
                    transaction: tx));
            }

            await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                "UPDATE SOLICITUD_COMPRA SET estado = 'Aprobada', proveedor_id = @ProveedorId WHERE id_solicitud_compra = @Id;",
                new { Id = id, r.ProveedorId }, transaction: tx));
            return true;
        });

        var aprobada = await ObtenerAsync(id);
        await _avisos.RegistrarAsync("compra_aprobada", "Compra aprobada",
            $"{aprobada.Orden?.Folio}: {string.Join(", ", r.Partidas.Select(p => p.Nombre.Trim()))} para {aprobada.ProyectoNombre}",
            Roles.Admin, Roles.ProyectoLider);
        return aprobada;
    }

    public async Task<SolicitudCompraAppDto> RechazarAsync(int id, string motivo)
    {
        var filas = await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
            "UPDATE SOLICITUD_COMPRA SET estado = 'Rechazada', motivo_rechazo = @Motivo WHERE id_solicitud_compra = @Id AND estado = 'Pendiente';",
            new { Id = id, Motivo = motivo.Trim() }, transaction: tx));
        if (filas == 0)
        {
            await ObtenerAsync(id); // 404 si no existe
            throw new ConflictoException("La solicitud ya fue atendida.");
        }
        return await ObtenerAsync(id);
    }

    public async Task EliminarAsync(int id)
    {
        var solicitud = await ObtenerAsync(id);
        if (solicitud.Estado == "Aprobada") throw new ConflictoException("Una solicitud aprobada no se puede eliminar.");
        await _db.RunAsync((cn, tx) => cn.ExecuteAsync("DELETE FROM SOLICITUD_COMPRA WHERE id_solicitud_compra = @Id;", new { Id = id }, transaction: tx));
    }
}
