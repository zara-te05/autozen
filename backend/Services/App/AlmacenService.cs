using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Errors;
using Dapper;

namespace Autozen.Api.Services;

/// <summary>Catálogo del almacén (un solo almacén físico), categorías y vales de salida de material.</summary>
public class AlmacenService
{
    public static readonly string[] Unidades = ["pieza", "kilogramo", "litro", "metro", "juego", "caja"];
    private static readonly string[] UnidadesDecimales = ["kilogramo", "litro", "metro"];
    public const string Material = "Material";
    public const string Herramienta = "Herramienta";

    private readonly DapperContext _db;

    public AlmacenService(DapperContext db) => _db = db;

    private sealed class ArticuloRow
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public int? CategoriaId { get; set; }
        public string Categoria { get; set; } = string.Empty;
        public string Tipo { get; set; } = Material;
        public string Unidad { get; set; } = "pieza";
        public decimal Existencia { get; set; }
        public decimal CostoUnitario { get; set; }
    }

    private sealed class SalidaRow
    {
        public int AlmacenId { get; set; }
        public decimal Cantidad { get; set; }
    }

    private sealed class ValeRow
    {
        public int Id { get; set; }
        public int ProyectoId { get; set; }
        public string TipoProyecto { get; set; } = Codigos.Cliente;
        public string ProyectoNombre { get; set; } = string.Empty;
        public int ArticuloId { get; set; }
        public string ArticuloNombre { get; set; } = string.Empty;
        public string Unidad { get; set; } = "pieza";
        public decimal Cantidad { get; set; }
        public decimal CostoUnitario { get; set; }
        public string EntregadoA { get; set; } = string.Empty;
        public DateTime Fecha { get; set; }
    }

    private const string SelectArticulos = @"
        SELECT a.id_almacen AS Id, a.""nombrePieza"" AS Nombre, a.categoria_id AS CategoriaId,
               COALESCE(cat.nombre, 'Sin categoría') AS Categoria, a.tipo_articulo AS Tipo, a.unidad_medida AS Unidad,
               COALESCE(a.""cantidadStock"", 0) AS Existencia, COALESCE(a.""costoPiezas"", 0) AS CostoUnitario
        FROM ALMACEN a
        LEFT JOIN CATEGORIA_ALMACEN cat ON cat.id_categoria = a.categoria_id
        WHERE a.activo";

    private static ArticuloDto ADto(ArticuloRow a) => new()
    {
        Id = a.Id,
        Codigo = Codigos.Articulo(a.Id),
        Nombre = a.Nombre,
        CategoriaId = a.CategoriaId,
        Categoria = a.Categoria,
        Tipo = a.Tipo,
        Unidad = a.Unidad,
        Existencia = a.Existencia,
        CostoUnitario = a.CostoUnitario,
    };

    // ------------------------------------------------------------------ Artículos

    public async Task<List<ArticuloDto>> ListarArticulosAsync()
    {
        var filas = await _db.RunAsync((cn, tx) => cn.QueryAsync<ArticuloRow>(SelectArticulos + @" ORDER BY lower(a.""nombrePieza"");", transaction: tx));
        return filas.Select(ADto).ToList();
    }

    public async Task<ArticuloDto> ObtenerArticuloAsync(int id)
    {
        var fila = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<ArticuloRow>(SelectArticulos + " AND a.id_almacen = @Id;", new { Id = id }, transaction: tx));
        return fila is null ? throw new NoEncontradoException($"El artículo #{id} no existe.") : ADto(fila);
    }

    public async Task<ArticuloDto> GuardarArticuloAsync(int? id, GuardarArticuloRequest r)
    {
        var nombre = r.Nombre.Trim();
        var tipo = NormalizarTipo(r.Tipo);
        var unidad = NormalizarUnidad(r.Unidad);
        if (nombre.Length == 0) throw new ReglaNegocioException("El nombre es obligatorio.");
        ValidarDecimales(unidad, r.Existencia, "La existencia");

        bool categoriaExiste = await _db.RunAsync((cn, tx) => cn.ExecuteScalarAsync<bool>(
            "SELECT EXISTS (SELECT 1 FROM CATEGORIA_ALMACEN WHERE id_categoria = @Id);", new { Id = r.CategoriaId }, transaction: tx));
        if (!categoriaExiste) throw new ReglaNegocioException("La categoría seleccionada no existe.");

        bool repetido = await _db.RunAsync((cn, tx) => cn.ExecuteScalarAsync<bool>(
            @"SELECT EXISTS (SELECT 1 FROM ALMACEN WHERE activo AND lower(""nombrePieza"") = lower(@Nombre) AND (@Id::int IS NULL OR id_almacen <> @Id));",
            new { Nombre = nombre, Id = id }, transaction: tx));
        if (repetido) throw new ConflictoException($"Ya existe un artículo llamado \"{nombre}\".");

        var parametros = new
        {
            Id = id,
            Nombre = nombre,
            r.CategoriaId,
            Tipo = tipo,
            Unidad = unidad,
            r.Existencia,
            r.CostoUnitario,
        };

        if (id is null)
        {
            int nuevoId = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<int>(
                @"INSERT INTO ALMACEN (""nombrePieza"", ""cantidadStock"", ""costoPiezas"", categoria_id, tipo_articulo, unidad_medida)
                  VALUES (@Nombre, @Existencia, @CostoUnitario, @CategoriaId, @Tipo, @Unidad) RETURNING id_almacen;",
                parametros, transaction: tx));
            return await ObtenerArticuloAsync(nuevoId);
        }

        var actual = await ObtenerArticuloAsync(id.Value);
        if (actual.Tipo != tipo && await PrestamosAbiertosAsync(id.Value) > 0)
            throw new ConflictoException("No se puede cambiar el tipo: hay herramientas de este artículo prestadas.");

        await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
            @"UPDATE ALMACEN SET ""nombrePieza"" = @Nombre, ""cantidadStock"" = @Existencia, ""costoPiezas"" = @CostoUnitario,
                  categoria_id = @CategoriaId, tipo_articulo = @Tipo, unidad_medida = @Unidad
              WHERE id_almacen = @Id AND activo;",
            parametros, transaction: tx));
        return await ObtenerArticuloAsync(id.Value);
    }

    /// <summary>Oculta el artículo del catálogo; los vales registrados se conservan.</summary>
    public async Task EliminarArticuloAsync(int id)
    {
        var articulo = await ObtenerArticuloAsync(id);
        if (await PrestamosAbiertosAsync(id) > 0)
            throw new ConflictoException($"No se puede eliminar \"{articulo.Nombre}\": tiene herramientas prestadas sin devolver.");
        await _db.RunAsync((cn, tx) => cn.ExecuteAsync("UPDATE ALMACEN SET activo = FALSE WHERE id_almacen = @Id;", new { Id = id }, transaction: tx));
    }

    private Task<int> PrestamosAbiertosAsync(int articuloId) => _db.RunAsync((cn, tx) => cn.ExecuteScalarAsync<int>(
        "SELECT COUNT(*)::int FROM EQUIPO_ALMACEN WHERE almacen_id = @Id AND fecha_devolucion IS NULL;", new { Id = articuloId }, transaction: tx));

    // ------------------------------------------------------------------ Categorías

    public async Task<List<CategoriaAlmacenDto>> ListarCategoriasAsync()
    {
        var filas = await _db.RunAsync((cn, tx) => cn.QueryAsync<CategoriaAlmacenDto>(
            @"SELECT c.id_categoria AS Id, c.nombre AS Nombre, (COUNT(a.id_almacen) FILTER (WHERE a.activo))::int AS Articulos
              FROM CATEGORIA_ALMACEN c
              LEFT JOIN ALMACEN a ON a.categoria_id = c.id_categoria
              GROUP BY c.id_categoria, c.nombre
              ORDER BY lower(c.nombre);", transaction: tx));
        return filas.ToList();
    }

    public async Task<CategoriaAlmacenDto> GuardarCategoriaAsync(int? id, GuardarCategoriaRequest r)
    {
        var nombre = r.Nombre.Trim();
        if (nombre.Length == 0) throw new ReglaNegocioException("Escribe el nombre de la categoría.");

        bool repetida = await _db.RunAsync((cn, tx) => cn.ExecuteScalarAsync<bool>(
            "SELECT EXISTS (SELECT 1 FROM CATEGORIA_ALMACEN WHERE lower(nombre) = lower(@Nombre) AND (@Id::int IS NULL OR id_categoria <> @Id));",
            new { Nombre = nombre, Id = id }, transaction: tx));
        if (repetida) throw new ConflictoException($"La categoría \"{nombre}\" ya existe.");

        int categoriaId;
        if (id is null)
        {
            categoriaId = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<int>(
                "INSERT INTO CATEGORIA_ALMACEN (nombre) VALUES (@Nombre) RETURNING id_categoria;", new { Nombre = nombre }, transaction: tx));
        }
        else
        {
            var filas = await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                "UPDATE CATEGORIA_ALMACEN SET nombre = @Nombre WHERE id_categoria = @Id;", new { Nombre = nombre, Id = id }, transaction: tx));
            if (filas == 0) throw new NoEncontradoException("La categoría no existe.");
            categoriaId = id.Value;
        }
        return (await ListarCategoriasAsync()).First(c => c.Id == categoriaId);
    }

    public async Task EliminarCategoriaAsync(int id)
    {
        var categoria = (await ListarCategoriasAsync()).FirstOrDefault(c => c.Id == id)
                        ?? throw new NoEncontradoException("La categoría no existe.");
        if (categoria.Articulos > 0)
            throw new ConflictoException($"No se puede eliminar \"{categoria.Nombre}\": la usan {categoria.Articulos} artículo(s). Cámbialos de categoría primero.");

        await _db.EnTransaccionAsync(async () =>
        {
            // Los artículos eliminados (inactivos) que aún la referencian quedan sin categoría
            await _db.RunAsync((cn, tx) => cn.ExecuteAsync("UPDATE ALMACEN SET categoria_id = NULL WHERE categoria_id = @Id;", new { Id = id }, transaction: tx));
            await _db.RunAsync((cn, tx) => cn.ExecuteAsync("DELETE FROM CATEGORIA_ALMACEN WHERE id_categoria = @Id;", new { Id = id }, transaction: tx));
            return true;
        });
    }

    // ------------------------------------------------------------------ Vales de material

    public async Task<List<ValeMaterialDto>> ListarValesMaterialAsync(int? proyectoId)
    {
        var filas = await _db.RunAsync((cn, tx) => cn.QueryAsync<ValeRow>(
            $@"SELECT sa.id_solicitud_almacen AS Id, sa.operacion_id AS ProyectoId, o.tipo_proyecto AS TipoProyecto,
                      {Codigos.NombreCamionSql} || ' (' || c.placas || ')' AS ProyectoNombre,
                      a.id_almacen AS ArticuloId, a.""nombrePieza"" AS ArticuloNombre, a.unidad_medida AS Unidad,
                      sa.""cantidadSolicitada"" AS Cantidad, sa.costo_unitario AS CostoUnitario,
                      COALESCE(sa.entregado_a, '') AS EntregadoA, sa.""fechaSolicitud"" AS Fecha
               FROM SOLICITUD_ALMACEN sa
               JOIN ALMACEN a ON a.id_almacen = sa.almacen_id
               JOIN OPERACIONES o ON o.id_operacion = sa.operacion_id
               JOIN CAMION c ON c.id_camion = o.camion_id
               WHERE (@ProyectoId::int IS NULL OR sa.operacion_id = @ProyectoId)
               ORDER BY sa.id_solicitud_almacen DESC;",
            new { ProyectoId = proyectoId }, transaction: tx));

        return filas.Select(v => new ValeMaterialDto
        {
            Id = v.Id,
            Codigo = Codigos.ValeMaterial(v.Id),
            ProyectoId = v.ProyectoId,
            ProyectoCodigo = Codigos.Proyecto(v.TipoProyecto, v.ProyectoId),
            ProyectoNombre = v.ProyectoNombre,
            ArticuloId = v.ArticuloId,
            ArticuloNombre = v.ArticuloNombre,
            Unidad = v.Unidad,
            Cantidad = v.Cantidad,
            CostoUnitario = v.CostoUnitario,
            Total = Math.Round(v.Cantidad * v.CostoUnitario, 2),
            EntregadoA = v.EntregadoA,
            Fecha = v.Fecha,
        }).ToList();
    }

    public async Task<ValeMaterialDto> CrearValeMaterialAsync(CrearValeMaterialRequest r)
    {
        int id = await _db.EnTransaccionAsync(async () =>
        {
            var articulo = await BloquearArticuloAsync(r.ArticuloId);
            if (articulo.Tipo != Material)
                throw new ReglaNegocioException($"\"{articulo.Nombre}\" es una herramienta: usa el vale de herramientas.");
            ValidarDecimales(articulo.Unidad, r.Cantidad, "La cantidad");
            await ValidarProyectoActivoAsync(r.ProyectoId);
            await DescontarAsync(articulo, r.Cantidad);

            var fecha = DateTime.Now;
            int valeId = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<int>(
                @"INSERT INTO SOLICITUD_ALMACEN (almacen_id, operacion_id, ""cantidadSolicitada"", ""fechaSolicitud"", costo_unitario, entregado_a)
                  VALUES (@ArticuloId, @ProyectoId, @Cantidad, @Fecha, @Costo, @EntregadoA) RETURNING id_solicitud_almacen;",
                new { r.ArticuloId, r.ProyectoId, r.Cantidad, Fecha = fecha, Costo = articulo.CostoUnitario, EntregadoA = r.EntregadoA?.Trim() },
                transaction: tx));

            // Kardex
            await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                @"INSERT INTO MOVIMIENTO_ALMACEN (almacen_id, solicitud_almacen_id, ""tipoMovimiento"", cantidad, ""fechaMovimiento"")
                  VALUES (@ArticuloId, @ValeId, 'Salida', @Cantidad, @Fecha);",
                new { r.ArticuloId, ValeId = valeId, r.Cantidad, Fecha = fecha }, transaction: tx));
            return valeId;
        });

        return (await ListarValesMaterialAsync(r.ProyectoId)).First(v => v.Id == id);
    }

    /// <summary>Cancela el vale: el material regresa al almacén y deja de contar en el proyecto.</summary>
    public async Task CancelarValeMaterialAsync(int id)
    {
        await _db.EnTransaccionAsync(async () =>
        {
            var vale = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<SalidaRow>(
                @"SELECT almacen_id AS AlmacenId, ""cantidadSolicitada"" AS Cantidad FROM SOLICITUD_ALMACEN WHERE id_solicitud_almacen = @Id FOR UPDATE;",
                new { Id = id }, transaction: tx));
            if (vale is null) throw new NoEncontradoException("El vale no existe.");

            await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                @"UPDATE ALMACEN SET ""cantidadStock"" = COALESCE(""cantidadStock"", 0) + @Cantidad WHERE id_almacen = @AlmacenId;",
                new { vale.AlmacenId, vale.Cantidad }, transaction: tx));
            await _db.RunAsync((cn, tx) => cn.ExecuteAsync("DELETE FROM MOVIMIENTO_ALMACEN WHERE solicitud_almacen_id = @Id;", new { Id = id }, transaction: tx));
            await _db.RunAsync((cn, tx) => cn.ExecuteAsync("DELETE FROM SOLICITUD_ALMACEN WHERE id_solicitud_almacen = @Id;", new { Id = id }, transaction: tx));
            return true;
        });
    }

    // ------------------------------------------------------------------ Entrega de placas / resguardos

    private const string SelectResguardos = @"
        SELECT id_resguardo AS Id, empresa AS Empresa, tipo_unidad AS TipoUnidad, numero_unidad AS NumeroUnidad, objetos AS Objetos,
               fecha_ingreso AS FechaIngreso, operador AS Operador, firma AS Firma, fecha_salida AS FechaSalida,
               entregado_a AS EntregadoA, notas_salida AS NotasSalida
        FROM RESGUARDO_ALMACEN";

    public async Task<List<ResguardoDto>> ListarResguardosAsync() =>
        (await _db.RunAsync((cn, tx) => cn.QueryAsync<ResguardoDto>(
            SelectResguardos + " ORDER BY (fecha_salida IS NULL) DESC, id_resguardo DESC LIMIT 500;", transaction: tx))).ToList();

    public async Task<ResguardoDto> RegistrarResguardoAsync(ResguardoDto r, int? usuarioId)
    {
        if (string.IsNullOrWhiteSpace(r.Empresa) || string.IsNullOrWhiteSpace(r.Objetos) || string.IsNullOrWhiteSpace(r.Operador))
            throw new ReglaNegocioException("Empresa, qué se entrega y operador son obligatorios.");
        if (!string.IsNullOrEmpty(r.Firma))
        {
            try { Convert.FromBase64String(r.Firma); }
            catch (FormatException) { throw new ReglaNegocioException("La firma no es válida."); }
        }

        return await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<ResguardoDto>(
            @"INSERT INTO RESGUARDO_ALMACEN (empresa, tipo_unidad, numero_unidad, objetos, fecha_ingreso, operador, firma, usuario_id)
              VALUES (@Empresa, @TipoUnidad, @NumeroUnidad, @Objetos, @FechaIngreso, @Operador, @Firma, @UsuarioId)
              RETURNING id_resguardo AS Id, empresa AS Empresa, tipo_unidad AS TipoUnidad, numero_unidad AS NumeroUnidad, objetos AS Objetos,
                        fecha_ingreso AS FechaIngreso, operador AS Operador, firma AS Firma, fecha_salida AS FechaSalida,
                        entregado_a AS EntregadoA, notas_salida AS NotasSalida;",
            new
            {
                Empresa = r.Empresa.Trim(),
                TipoUnidad = r.TipoUnidad?.Trim(),
                NumeroUnidad = string.IsNullOrWhiteSpace(r.NumeroUnidad) ? "S/N" : r.NumeroUnidad.Trim(),
                Objetos = r.Objetos.Trim(),
                FechaIngreso = r.FechaIngreso == default ? DateTime.Now : r.FechaIngreso,
                Operador = r.Operador.Trim(),
                r.Firma,
                UsuarioId = usuarioId,
            }, transaction: tx));
    }

    public async Task<ResguardoDto> RegistrarSalidaResguardoAsync(int id, SalidaResguardoRequest r)
    {
        var resultado = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<ResguardoDto>(
            @"UPDATE RESGUARDO_ALMACEN SET fecha_salida = @Fecha, entregado_a = @EntregadoA, notas_salida = @Notas
              WHERE id_resguardo = @Id AND fecha_salida IS NULL
              RETURNING id_resguardo AS Id, empresa AS Empresa, tipo_unidad AS TipoUnidad, numero_unidad AS NumeroUnidad, objetos AS Objetos,
                        fecha_ingreso AS FechaIngreso, operador AS Operador, firma AS Firma, fecha_salida AS FechaSalida,
                        entregado_a AS EntregadoA, notas_salida AS NotasSalida;",
            new { Id = id, Fecha = DateTime.Now, EntregadoA = r.EntregadoA.Trim(), Notas = r.Notas?.Trim() }, transaction: tx));
        return resultado ?? throw new ConflictoException("El registro no existe o ya tiene salida.");
    }

    public async Task EliminarResguardoAsync(int id)
    {
        var filas = await _db.RunAsync((cn, tx) => cn.ExecuteAsync("DELETE FROM RESGUARDO_ALMACEN WHERE id_resguardo = @Id;", new { Id = id }, transaction: tx));
        if (filas == 0) throw new NoEncontradoException("El registro no existe.");
    }

    // ------------------------------------------------------------------ Auxiliares compartidos

    /// <summary>Lee el artículo bloqueando su fila hasta que termine la transacción.</summary>
    internal async Task<ArticuloDto> BloquearArticuloAsync(int id)
    {
        var fila = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<ArticuloRow>(
            SelectArticulos + " AND a.id_almacen = @Id FOR UPDATE OF a;", new { Id = id }, transaction: tx));
        return fila is null ? throw new NoEncontradoException("El artículo no existe en el almacén.") : ADto(fila);
    }

    internal async Task ValidarProyectoActivoAsync(int proyectoId)
    {
        var archivado = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<bool?>(
            "SELECT archivado FROM OPERACIONES WHERE id_operacion = @Id;", new { Id = proyectoId }, transaction: tx));
        if (archivado is null) throw new NoEncontradoException("El proyecto no existe.");
        if (archivado.Value) throw new ConflictoException("El proyecto está archivado.");
    }

    /// <summary>Descuento atómico: falla si no alcanza la existencia.</summary>
    internal async Task DescontarAsync(ArticuloDto articulo, decimal cantidad)
    {
        var filas = await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
            @"UPDATE ALMACEN SET ""cantidadStock"" = ""cantidadStock"" - @Cantidad WHERE id_almacen = @Id AND ""cantidadStock"" >= @Cantidad;",
            new { articulo.Id, Cantidad = cantidad }, transaction: tx));
        if (filas == 0)
            throw new ConflictoException($"Solo hay {articulo.Existencia:0.###} {articulo.Unidad} de \"{articulo.Nombre}\" en almacén.");
    }

    internal static void ValidarDecimales(string unidad, decimal cantidad, string campo)
    {
        if (!UnidadesDecimales.Contains(unidad) && cantidad != decimal.Truncate(cantidad))
            throw new ReglaNegocioException($"{campo} debe ser un número entero para artículos por {unidad}.");
    }

    private static string NormalizarTipo(string? tipo) =>
        string.Equals(tipo?.Trim(), Herramienta, StringComparison.OrdinalIgnoreCase) ? Herramienta
        : string.Equals(tipo?.Trim(), Material, StringComparison.OrdinalIgnoreCase) ? Material
        : throw new ReglaNegocioException("El tipo debe ser 'Material' o 'Herramienta'.");

    private static string NormalizarUnidad(string? unidad)
    {
        var u = unidad?.Trim().ToLowerInvariant() ?? string.Empty;
        return Unidades.Contains(u) ? u : throw new ReglaNegocioException($"Unidad no válida. Usa: {string.Join(", ", Unidades)}.");
    }
}
