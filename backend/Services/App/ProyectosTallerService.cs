using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Errors;
using Dapper;

namespace Autozen.Api.Services;

/// <summary>
/// Proyectos del taller tal como los maneja la app: tipo (cliente o aseguradora), etapas configurables,
/// datos de la Evaluación de Daños, fotos y archivado.
/// </summary>
public class ProyectosTallerService
{
    public const int MaxEtapas = 15;
    private const long MaxBytesFoto = 10 * 1024 * 1024;

    private static readonly Dictionary<string, string> ExtensionesFoto = new(StringComparer.OrdinalIgnoreCase)
    {
        ["image/jpeg"] = ".jpg",
        ["image/png"] = ".png",
        ["image/webp"] = ".webp",
        ["image/heic"] = ".heic",
    };

    private const long MaxBytesPdf = 20 * 1024 * 1024;

    private readonly DapperContext _db;
    private readonly NotificacionService _avisos;
    private readonly string _carpetaFotos;
    private readonly string _carpetaDocumentos;

    public ProyectosTallerService(DapperContext db, NotificacionService avisos, IConfiguration config, IWebHostEnvironment env)
    {
        _db = db;
        _avisos = avisos;
        var carpeta = config["Fotos:Carpeta"];
        _carpetaFotos = string.IsNullOrWhiteSpace(carpeta) ? Path.Combine(env.ContentRootPath, "fotos") : carpeta;
        // Los PDFs viven en una subcarpeta de la misma carpeta de archivos
        _carpetaDocumentos = Path.Combine(_carpetaFotos, "documentos");
    }

    private sealed class DocumentoRow
    {
        public int Id { get; set; }
        public int OperacionId { get; set; }
        public string NombreOriginal { get; set; } = string.Empty;
        public string NombreArchivo { get; set; } = string.Empty;
        public long Tamano { get; set; }
        public DateTime FechaSubida { get; set; }
    }

    private const string SelectDocumentos =
        "SELECT id_documento AS Id, operacion_id AS OperacionId, nombre_original AS NombreOriginal, nombre_archivo AS NombreArchivo, tamano AS Tamano, fecha_subida AS FechaSubida FROM PROYECTO_DOCUMENTO";

    private static DocumentoProyectoDto DocDto(DocumentoRow d) => new()
    {
        Id = d.Id,
        Nombre = d.NombreOriginal,
        Url = $"/api/Proyecto/{d.OperacionId}/documentos/{d.Id}",
        Tamano = d.Tamano,
        FechaSubida = d.FechaSubida,
    };

    private sealed class ProyectoRow
    {
        public int Id { get; set; }
        public string Tipo { get; set; } = Codigos.Cliente;
        public string NombreCamion { get; set; } = string.Empty;
        public string Placa { get; set; } = string.Empty;
        public string Cliente { get; set; } = string.Empty;
        public string? Aseguradora { get; set; }
        public string? NumeroSiniestro { get; set; }
        public string? Responsable { get; set; }
        public DateTime FechaIngreso { get; set; }
        public DateTime? FechaEntregaComprometida { get; set; }
        public int EtapaActual { get; set; }
        public bool Archivado { get; set; }
        public DateTime? FechaEvaluacion { get; set; }
        public string? DescripcionDanos { get; set; }
    }

    private sealed class EtapaRow
    {
        public int OperacionId { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public int DiasEstimados { get; set; }
    }

    private sealed class RefaccionRow
    {
        public int OperacionId { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public int Cantidad { get; set; }
    }

    private sealed class FotoRow
    {
        public int Id { get; set; }
        public int OperacionId { get; set; }
        public string NombreArchivo { get; set; } = string.Empty;
        public string TipoContenido { get; set; } = string.Empty;
        public DateTime FechaSubida { get; set; }
    }

    private const string SelectProyectos = $@"
        SELECT o.id_operacion AS Id,
               o.tipo_proyecto AS Tipo,
               {Codigos.NombreCamionSql} AS NombreCamion,
               c.placas AS Placa,
               COALESCE(TRIM(cl.nombre || ' ' || COALESCE(cl.apellido, '')), '') AS Cliente,
               o.aseguradora AS Aseguradora,
               o.numero_siniestro AS NumeroSiniestro,
               o.responsable AS Responsable,
               o.""fechaInicio"" AS FechaIngreso,
               o.fecha_entrega_comprometida AS FechaEntregaComprometida,
               o.etapa_actual AS EtapaActual,
               o.archivado AS Archivado,
               o.fecha_evaluacion AS FechaEvaluacion,
               o.descripcion_danos AS DescripcionDanos
        FROM OPERACIONES o
        JOIN CAMION c ON c.id_camion = o.camion_id
        LEFT JOIN CLIENTE cl ON cl.id_cliente = c.cliente_id
        WHERE COALESCE(o.""estadoOperacion"", '') <> 'Eliminado'";

    // ------------------------------------------------------------------ Consultas

    public async Task<List<ProyectoTallerDto>> ListarAsync(string? tipo, bool? archivados)
    {
        var sql = SelectProyectos
                  + " AND (@Tipo::text IS NULL OR o.tipo_proyecto = @Tipo)"
                  + " AND (@Archivados::boolean IS NULL OR o.archivado = @Archivados)"
                  + " ORDER BY o.id_operacion DESC;";
        string? tipoNormalizado = string.IsNullOrWhiteSpace(tipo) ? null : NormalizarTipo(tipo);
        var filas = (await _db.RunAsync((cn, tx) =>
            cn.QueryAsync<ProyectoRow>(sql, new { Tipo = tipoNormalizado, Archivados = archivados }, transaction: tx))).ToList();
        return await CompletarAsync(filas);
    }

    public async Task<ProyectoTallerDto> ObtenerAsync(int id)
    {
        var fila = await _db.RunAsync((cn, tx) =>
            cn.QueryFirstOrDefaultAsync<ProyectoRow>(SelectProyectos + " AND o.id_operacion = @Id;", new { Id = id }, transaction: tx));
        if (fila is null) throw new NoEncontradoException($"El proyecto #{id} no existe.");
        return (await CompletarAsync([fila]))[0];
    }

    private async Task<List<ProyectoTallerDto>> CompletarAsync(List<ProyectoRow> filas)
    {
        if (filas.Count == 0) return [];
        var ids = filas.Select(f => f.Id).ToArray();

        var etapas = await _db.RunAsync((cn, tx) => cn.QueryAsync<EtapaRow>(
            "SELECT operacion_id AS OperacionId, nombre AS Nombre, dias_estimados AS DiasEstimados FROM PROYECTO_ETAPA WHERE operacion_id = ANY(@Ids) ORDER BY operacion_id, orden;",
            new { Ids = ids }, transaction: tx));
        var refacciones = await _db.RunAsync((cn, tx) => cn.QueryAsync<RefaccionRow>(
            "SELECT operacion_id AS OperacionId, nombre AS Nombre, cantidad AS Cantidad FROM PROYECTO_REFACCION WHERE operacion_id = ANY(@Ids) ORDER BY id_refaccion;",
            new { Ids = ids }, transaction: tx));
        var fotos = await _db.RunAsync((cn, tx) => cn.QueryAsync<FotoRow>(
            "SELECT id_foto AS Id, operacion_id AS OperacionId, nombre_archivo AS NombreArchivo, tipo_contenido AS TipoContenido, fecha_subida AS FechaSubida FROM PROYECTO_FOTO WHERE operacion_id = ANY(@Ids) ORDER BY id_foto;",
            new { Ids = ids }, transaction: tx));

        var documentos = await _db.RunAsync((cn, tx) => cn.QueryAsync<DocumentoRow>(
            SelectDocumentos + " WHERE operacion_id = ANY(@Ids) ORDER BY id_documento;", new { Ids = ids }, transaction: tx));
        var documentosPor = documentos.ToLookup(d => d.OperacionId);

        var etapasPor = etapas.ToLookup(e => e.OperacionId);
        var refaccionesPor = refacciones.ToLookup(r => r.OperacionId);
        var fotosPor = fotos.ToLookup(f => f.OperacionId);

        return filas.Select(f => new ProyectoTallerDto
        {
            Id = f.Id,
            Codigo = Codigos.Proyecto(f.Tipo, f.Id),
            Tipo = f.Tipo,
            NombreCamion = f.NombreCamion,
            Placa = f.Placa,
            Cliente = f.Cliente,
            Aseguradora = f.Aseguradora,
            NumeroSiniestro = f.NumeroSiniestro,
            Responsable = f.Responsable ?? string.Empty,
            FechaIngreso = f.FechaIngreso,
            FechaEntregaComprometida = f.FechaEntregaComprometida,
            EtapaActual = f.EtapaActual,
            Archivado = f.Archivado,
            FechaEvaluacion = f.FechaEvaluacion,
            DescripcionDanos = f.DescripcionDanos ?? string.Empty,
            Etapas = etapasPor[f.Id].Select(e => new EtapaProyectoDto { Nombre = e.Nombre, DiasEstimados = e.DiasEstimados }).ToList(),
            Refacciones = refaccionesPor[f.Id].Select(r => new RefaccionCotizadaDto { Nombre = r.Nombre, Cantidad = r.Cantidad }).ToList(),
            Fotos = fotosPor[f.Id].Select(x => new FotoProyectoDto
            {
                Id = x.Id,
                Url = $"/api/Proyecto/{f.Id}/fotos/{x.Id}",
                FechaSubida = x.FechaSubida
            }).ToList(),
            Documentos = documentosPor[f.Id].Select(DocDto).ToList(),
        }).ToList();
    }

    // ------------------------------------------------------------------ Escritura

    public async Task<ProyectoTallerDto> CrearAsync(GuardarProyectoRequest r, int? usuarioId)
    {
        var tipo = NormalizarTipo(r.Tipo);
        Validar(r, tipo);
        var fechaIngreso = (r.FechaIngreso ?? DateTime.Now).Date;
        var fechaFin = FechaFin(r, tipo, fechaIngreso);

        int id = await _db.EnTransaccionAsync(async () =>
        {
            int? clienteId = tipo == Codigos.Cliente ? await ObtenerOCrearClienteAsync(r.Cliente!.Trim()) : null;

            int camionId = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<int>(
                @"INSERT INTO CAMION (cliente_id, placas, nombre, ""fechaEntrada"", ""tiempoEsperado"")
                  VALUES (@ClienteId, @Placa, @Nombre, @FechaIngreso, @FechaFin) RETURNING id_camion;",
                new { ClienteId = clienteId, Placa = r.Placa.Trim().ToUpperInvariant(), Nombre = r.NombreCamion.Trim(), FechaIngreso = fechaIngreso, FechaFin = fechaFin },
                transaction: tx));

            int operacionId = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<int>(
                @"INSERT INTO OPERACIONES (camion_id, usuario_id, ""fechaInicio"", ""fechaEstimadaFinalizacion"", ""estadoOperacion"",
                                           tipo_proyecto, aseguradora, numero_siniestro, fecha_entrega_comprometida, etapa_actual,
                                           responsable, fecha_evaluacion, descripcion_danos)
                  VALUES (@CamionId, @UsuarioId, @FechaIngreso, @FechaFin, @Estado,
                          @Tipo, @Aseguradora, @Siniestro, @FechaEntrega, @EtapaActual,
                          @Responsable, @FechaEvaluacion, @Descripcion)
                  RETURNING id_operacion;",
                new
                {
                    CamionId = camionId,
                    UsuarioId = usuarioId,
                    FechaIngreso = fechaIngreso,
                    FechaFin = fechaFin,
                    Estado = r.EtapaActual >= r.Etapas.Count ? "Finalizado" : "En Proceso",
                    Tipo = tipo,
                    Aseguradora = tipo == Codigos.Aseguradora ? r.Aseguradora!.Trim() : null,
                    Siniestro = tipo == Codigos.Aseguradora ? Limpio(r.NumeroSiniestro) : null,
                    FechaEntrega = tipo == Codigos.Aseguradora ? r.FechaEntregaComprometida!.Value.Date : (DateTime?)null,
                    r.EtapaActual,
                    Responsable = Limpio(r.Responsable),
                    FechaEvaluacion = r.FechaEvaluacion ?? fechaIngreso,
                    Descripcion = r.DescripcionDanos?.Trim() ?? string.Empty,
                },
                transaction: tx));

            await GuardarEtapasAsync(operacionId, r.Etapas);
            await GuardarRefaccionesAsync(operacionId, r.Refacciones ?? []);
            return operacionId;
        });

        var creado = await ObtenerAsync(id);
        await _avisos.RegistrarAsync("proyecto_nuevo", "Se abrió un nuevo proyecto",
            $"{creado.Codigo}: {creado.NombreCamion} ({creado.Placa}) • {(creado.Tipo == Codigos.Aseguradora ? creado.Aseguradora : creado.Cliente)}",
            Roles.Admin);
        return creado;
    }

    public async Task<ProyectoTallerDto> ActualizarAsync(int id, GuardarProyectoRequest r)
    {
        var actual = await ObtenerAsync(id);
        if (actual.Archivado) throw new ConflictoException("El proyecto está archivado. Restáuralo para editarlo.");
        var tipo = actual.Tipo; // el tipo no cambia
        Validar(r, tipo);
        var fechaFin = FechaFin(r, tipo, actual.FechaIngreso.Date);

        await _db.EnTransaccionAsync(async () =>
        {
            int? clienteId = tipo == Codigos.Cliente ? await ObtenerOCrearClienteAsync(r.Cliente!.Trim()) : null;

            await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                @"UPDATE CAMION c SET cliente_id = @ClienteId, placas = @Placa, nombre = @Nombre, ""tiempoEsperado"" = @FechaFin
                  FROM OPERACIONES o WHERE o.camion_id = c.id_camion AND o.id_operacion = @Id;",
                new { Id = id, ClienteId = clienteId, Placa = r.Placa.Trim().ToUpperInvariant(), Nombre = r.NombreCamion.Trim(), FechaFin = fechaFin },
                transaction: tx));

            await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                @"UPDATE OPERACIONES SET
                      ""fechaEstimadaFinalizacion"" = @FechaFin,
                      ""estadoOperacion"" = @Estado,
                      aseguradora = @Aseguradora,
                      numero_siniestro = @Siniestro,
                      fecha_entrega_comprometida = @FechaEntrega,
                      etapa_actual = @EtapaActual,
                      responsable = @Responsable,
                      descripcion_danos = COALESCE(@Descripcion, descripcion_danos)
                  WHERE id_operacion = @Id;",
                new
                {
                    Id = id,
                    FechaFin = fechaFin,
                    Estado = r.EtapaActual >= r.Etapas.Count ? "Finalizado" : "En Proceso",
                    Aseguradora = tipo == Codigos.Aseguradora ? r.Aseguradora!.Trim() : null,
                    Siniestro = tipo == Codigos.Aseguradora ? Limpio(r.NumeroSiniestro) : null,
                    FechaEntrega = tipo == Codigos.Aseguradora ? r.FechaEntregaComprometida!.Value.Date : (DateTime?)null,
                    r.EtapaActual,
                    Responsable = Limpio(r.Responsable),
                    Descripcion = r.DescripcionDanos?.Trim(),
                },
                transaction: tx));

            await _db.RunAsync((cn, tx) => cn.ExecuteAsync("DELETE FROM PROYECTO_ETAPA WHERE operacion_id = @Id;", new { Id = id }, transaction: tx));
            await GuardarEtapasAsync(id, r.Etapas);

            if (r.Refacciones is not null)
            {
                await _db.RunAsync((cn, tx) => cn.ExecuteAsync("DELETE FROM PROYECTO_REFACCION WHERE operacion_id = @Id;", new { Id = id }, transaction: tx));
                await GuardarRefaccionesAsync(id, r.Refacciones);
            }
            return true;
        });

        var editado = await ObtenerAsync(id);
        await _avisos.RegistrarAsync("proyecto_editado", "Se editó un proyecto",
            $"{editado.Codigo}: {editado.NombreCamion} ({editado.Placa})", Roles.Admin);
        return editado;
    }

    public async Task<ProyectoTallerDto> AvanzarEtapaAsync(int id)
    {
        var filas = await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
            @"UPDATE OPERACIONES o SET
                  etapa_actual = etapa_actual + 1,
                  ""estadoOperacion"" = CASE
                      WHEN etapa_actual + 1 >= (SELECT COUNT(*) FROM PROYECTO_ETAPA e WHERE e.operacion_id = o.id_operacion) THEN 'Finalizado'
                      ELSE 'En Proceso' END
              WHERE o.id_operacion = @Id
                AND NOT o.archivado
                AND o.etapa_actual < (SELECT COUNT(*) FROM PROYECTO_ETAPA e WHERE e.operacion_id = o.id_operacion);",
            new { Id = id }, transaction: tx));
        if (filas == 0)
        {
            var proyecto = await ObtenerAsync(id); // lanza 404 si no existe
            throw new ConflictoException(proyecto.Archivado
                ? "El proyecto está archivado."
                : "El proyecto ya completó todas sus etapas.");
        }
        return await ObtenerAsync(id);
    }

    public async Task<ProyectoTallerDto> CambiarArchivadoAsync(int id, bool archivado)
    {
        var filas = await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
            "UPDATE OPERACIONES SET archivado = @Archivado WHERE id_operacion = @Id;", new { Id = id, Archivado = archivado }, transaction: tx));
        if (filas == 0) throw new NoEncontradoException($"El proyecto #{id} no existe.");
        return await ObtenerAsync(id);
    }

    // ------------------------------------------------------------------ Fotos

    public async Task<FotoProyectoDto> AgregarFotoAsync(int id, IFormFile archivo)
    {
        await ObtenerAsync(id);
        if (archivo.Length == 0) throw new ReglaNegocioException("La foto está vacía.");
        if (archivo.Length > MaxBytesFoto) throw new ReglaNegocioException("La foto pesa más de 10 MB.");
        if (!ExtensionesFoto.TryGetValue(archivo.ContentType, out var extension))
            throw new ReglaNegocioException("Formato no permitido. Usa JPG, PNG, WEBP o HEIC.");

        Directory.CreateDirectory(_carpetaFotos);
        var nombre = $"{id}_{Guid.NewGuid():N}{extension}";
        var ruta = Path.Combine(_carpetaFotos, nombre);
        await using (var destino = File.Create(ruta))
        {
            await archivo.CopyToAsync(destino);
        }

        try
        {
            var foto = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<FotoRow>(
                @"INSERT INTO PROYECTO_FOTO (operacion_id, nombre_archivo, tipo_contenido) VALUES (@Id, @Nombre, @Tipo)
                  RETURNING id_foto AS Id, operacion_id AS OperacionId, nombre_archivo AS NombreArchivo, tipo_contenido AS TipoContenido, fecha_subida AS FechaSubida;",
                new { Id = id, Nombre = nombre, Tipo = archivo.ContentType }, transaction: tx));
            return new FotoProyectoDto { Id = foto.Id, Url = $"/api/Proyecto/{id}/fotos/{foto.Id}", FechaSubida = foto.FechaSubida };
        }
        catch
        {
            File.Delete(ruta);
            throw;
        }
    }

    public async Task<(string Ruta, string TipoContenido)> ObtenerFotoAsync(int id, int idFoto)
    {
        var foto = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<FotoRow>(
            "SELECT id_foto AS Id, operacion_id AS OperacionId, nombre_archivo AS NombreArchivo, tipo_contenido AS TipoContenido, fecha_subida AS FechaSubida FROM PROYECTO_FOTO WHERE id_foto = @IdFoto AND operacion_id = @Id;",
            new { Id = id, IdFoto = idFoto }, transaction: tx));
        if (foto is null) throw new NoEncontradoException("La foto no existe.");
        var ruta = Path.Combine(_carpetaFotos, foto.NombreArchivo);
        if (!File.Exists(ruta)) throw new NoEncontradoException("El archivo de la foto ya no está en el servidor.");
        return (ruta, foto.TipoContenido);
    }

    public async Task EliminarFotoAsync(int id, int idFoto)
    {
        var nombre = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<string?>(
            "DELETE FROM PROYECTO_FOTO WHERE id_foto = @IdFoto AND operacion_id = @Id RETURNING nombre_archivo;",
            new { Id = id, IdFoto = idFoto }, transaction: tx));
        if (nombre is null) throw new NoEncontradoException("La foto no existe.");
        var ruta = Path.Combine(_carpetaFotos, nombre);
        if (File.Exists(ruta)) File.Delete(ruta);
    }

    // ------------------------------------------------------------------ PDFs de la aseguradora

    public async Task<DocumentoProyectoDto> AgregarDocumentoAsync(int id, IFormFile archivo)
    {
        await ObtenerAsync(id);
        if (archivo.Length == 0) throw new ReglaNegocioException("El archivo está vacío.");
        if (archivo.Length > MaxBytesPdf) throw new ReglaNegocioException("El PDF pesa más de 20 MB.");
        var nombreOriginal = Path.GetFileName(archivo.FileName);
        if (!nombreOriginal.EndsWith(".pdf", StringComparison.OrdinalIgnoreCase))
            throw new ReglaNegocioException("Solo se pueden subir archivos PDF.");

        // Verifica que de verdad sea un PDF (empieza con "%PDF")
        var cabecera = new byte[4];
        await using (var lectura = archivo.OpenReadStream())
        {
            var leidos = await lectura.ReadAsync(cabecera);
            if (leidos < 4 || cabecera[0] != '%' || cabecera[1] != 'P' || cabecera[2] != 'D' || cabecera[3] != 'F')
                throw new ReglaNegocioException("El archivo no es un PDF válido.");
        }

        Directory.CreateDirectory(_carpetaDocumentos);
        var nombre = $"{id}_{Guid.NewGuid():N}.pdf";
        var ruta = Path.Combine(_carpetaDocumentos, nombre);
        await using (var destino = File.Create(ruta))
        {
            await archivo.CopyToAsync(destino);
        }

        try
        {
            var doc = await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<DocumentoRow>(
                @"INSERT INTO PROYECTO_DOCUMENTO (operacion_id, nombre_original, nombre_archivo, tamano) VALUES (@Id, @Original, @Nombre, @Tamano)
                  RETURNING id_documento AS Id, operacion_id AS OperacionId, nombre_original AS NombreOriginal, nombre_archivo AS NombreArchivo, tamano AS Tamano, fecha_subida AS FechaSubida;",
                new { Id = id, Original = nombreOriginal.Length > 200 ? nombreOriginal[^200..] : nombreOriginal, Nombre = nombre, Tamano = archivo.Length },
                transaction: tx));
            return DocDto(doc);
        }
        catch
        {
            File.Delete(ruta);
            throw;
        }
    }

    public async Task<(string Ruta, string Nombre)> ObtenerDocumentoAsync(int id, int idDocumento)
    {
        var doc = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<DocumentoRow>(
            SelectDocumentos + " WHERE id_documento = @IdDoc AND operacion_id = @Id;", new { Id = id, IdDoc = idDocumento }, transaction: tx));
        if (doc is null) throw new NoEncontradoException("El documento no existe.");
        var ruta = Path.Combine(_carpetaDocumentos, doc.NombreArchivo);
        if (!File.Exists(ruta)) throw new NoEncontradoException("El archivo ya no está en el servidor.");
        return (ruta, doc.NombreOriginal);
    }

    public async Task EliminarDocumentoAsync(int id, int idDocumento)
    {
        var nombre = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<string?>(
            "DELETE FROM PROYECTO_DOCUMENTO WHERE id_documento = @IdDoc AND operacion_id = @Id RETURNING nombre_archivo;",
            new { Id = id, IdDoc = idDocumento }, transaction: tx));
        if (nombre is null) throw new NoEncontradoException("El documento no existe.");
        var ruta = Path.Combine(_carpetaDocumentos, nombre);
        if (File.Exists(ruta)) File.Delete(ruta);
    }

    // ------------------------------------------------------------------ Auxiliares

    private static string NormalizarTipo(string? tipo)
    {
        if (string.Equals(tipo?.Trim(), Codigos.Aseguradora, StringComparison.OrdinalIgnoreCase)) return Codigos.Aseguradora;
        if (string.Equals(tipo?.Trim(), Codigos.Cliente, StringComparison.OrdinalIgnoreCase)) return Codigos.Cliente;
        throw new ReglaNegocioException("El tipo de proyecto debe ser 'Cliente' o 'Aseguradora'.");
    }

    private static string? Limpio(string? texto) => string.IsNullOrWhiteSpace(texto) ? null : texto.Trim();

    private static void Validar(GuardarProyectoRequest r, string tipo)
    {
        if (string.IsNullOrWhiteSpace(r.NombreCamion)) throw new ReglaNegocioException("El nombre del camión es obligatorio.");
        if (string.IsNullOrWhiteSpace(r.Placa)) throw new ReglaNegocioException("La placa es obligatoria.");

        if (tipo == Codigos.Cliente && string.IsNullOrWhiteSpace(r.Cliente))
            throw new ReglaNegocioException("El nombre del cliente es obligatorio.");
        if (tipo == Codigos.Aseguradora)
        {
            if (string.IsNullOrWhiteSpace(r.Aseguradora)) throw new ReglaNegocioException("La aseguradora es obligatoria.");
            if (r.FechaEntregaComprometida is null) throw new ReglaNegocioException("La fecha de entrega comprometida es obligatoria.");
        }

        if (r.Etapas.Count is < 1 or > MaxEtapas)
            throw new ReglaNegocioException($"El proyecto debe tener entre 1 y {MaxEtapas} etapas.");
        if (r.Etapas.Any(e => string.IsNullOrWhiteSpace(e.Nombre)))
            throw new ReglaNegocioException("Todas las etapas necesitan nombre.");
        if (r.Etapas.Any(e => e.DiasEstimados is < 1 or > 365))
            throw new ReglaNegocioException("Los días de cada etapa deben estar entre 1 y 365.");
        if (r.EtapaActual > r.Etapas.Count)
            throw new ReglaNegocioException("La etapa en curso no existe.");
    }

    /// <summary>Aseguradora: la fecha comprometida. Cliente: ingreso + suma de días de las etapas.</summary>
    private static DateTime FechaFin(GuardarProyectoRequest r, string tipo, DateTime fechaIngreso) =>
        tipo == Codigos.Aseguradora
            ? r.FechaEntregaComprometida!.Value.Date
            : fechaIngreso.AddDays(r.Etapas.Sum(e => e.DiasEstimados));

    private async Task<int> ObtenerOCrearClienteAsync(string nombre)
    {
        var existente = await _db.RunAsync((cn, tx) => cn.QueryFirstOrDefaultAsync<int?>(
            "SELECT id_cliente FROM CLIENTE WHERE lower(TRIM(nombre || ' ' || COALESCE(apellido, ''))) = lower(@Nombre) ORDER BY id_cliente LIMIT 1;",
            new { Nombre = nombre }, transaction: tx));
        if (existente is not null) return existente.Value;

        return await _db.RunAsync((cn, tx) => cn.QuerySingleAsync<int>(
            @"INSERT INTO CLIENTE (nombre, apellido, ""numTelefono"", ""lugarProcedencia"") VALUES (@Nombre, '', '', 'Local') RETURNING id_cliente;",
            new { Nombre = nombre }, transaction: tx));
    }

    private async Task GuardarEtapasAsync(int operacionId, List<EtapaProyectoDto> etapas)
    {
        for (int i = 0; i < etapas.Count; i++)
        {
            var etapa = etapas[i];
            await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                "INSERT INTO PROYECTO_ETAPA (operacion_id, orden, nombre, dias_estimados) VALUES (@OperacionId, @Orden, @Nombre, @Dias);",
                new { OperacionId = operacionId, Orden = i, Nombre = etapa.Nombre.Trim(), Dias = etapa.DiasEstimados }, transaction: tx));
        }
    }

    private async Task GuardarRefaccionesAsync(int operacionId, List<RefaccionCotizadaDto> refacciones)
    {
        foreach (var r in refacciones.Where(r => !string.IsNullOrWhiteSpace(r.Nombre)))
        {
            await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                "INSERT INTO PROYECTO_REFACCION (operacion_id, nombre, cantidad) VALUES (@OperacionId, @Nombre, @Cantidad);",
                new { OperacionId = operacionId, Nombre = r.Nombre.Trim(), Cantidad = Math.Max(1, r.Cantidad) }, transaction: tx));
        }
    }
}
