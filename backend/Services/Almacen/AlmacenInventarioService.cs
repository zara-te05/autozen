using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Dapper;

namespace Autozen.Api.Services;

public class AlmacenInventarioService
{
    private readonly DapperContext _context;
    private readonly IAlmacenRepository _almacenRepo;
    private readonly ISolicitudAlmacenRepository _solicitudAlmacenRepo;
    private readonly IMovimientoAlmacenRepository _movimientoRepo;
    private readonly IOperacionRepository _operacionRepo;

    public AlmacenInventarioService(
        DapperContext context,
        IAlmacenRepository almacenRepo,
        ISolicitudAlmacenRepository solicitudAlmacenRepo,
        IMovimientoAlmacenRepository movimientoRepo,
        IOperacionRepository operacionRepo)
    {
        _context = context;
        _almacenRepo = almacenRepo;
        _solicitudAlmacenRepo = solicitudAlmacenRepo;
        _movimientoRepo = movimientoRepo;
        _operacionRepo = operacionRepo;
    }

    /// <summary>
    /// Da de alta una nueva pieza o refacción en el catálogo de almacén.
    /// </summary>
    public async Task<Almacen> CrearPiezaAsync(CrearPiezaAlmacenRequestDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.NombrePieza))
            throw new InvalidOperationException("El nombre de la pieza es obligatorio.");

        if (dto.CantidadStock < 0)
            throw new InvalidOperationException("El stock inicial no puede ser negativo.");

        if (dto.CostoPiezas < 0)
            throw new InvalidOperationException("El costo no puede ser negativo.");

        var nuevoItem = new CreateAlmacenDto
        {
            NombrePieza = dto.NombrePieza.Trim(),
            CantidadStock = dto.CantidadStock,
            CostoPiezas = dto.CostoPiezas
        };

        return await _almacenRepo.CreateAsync(nuevoItem);
    }

    /// <summary>
    /// Consulta el catálogo completo de piezas con su stock y costos actuales.
    /// </summary>
    public async Task<IEnumerable<Almacen>> GetAllStockAsync()
    {
        return await _almacenRepo.GetAllAsync();
    }

    /// <summary>
    /// Obtiene una pieza específica por su ID.
    /// </summary>
    public async Task<Almacen?> GetStockByIdAsync(int id)
    {
        return await _almacenRepo.GetByIdAsync(id);
    }

    /// <summary>
    /// Registra la salida de material hacia un proyecto, descuenta el inventario y calcula el cobro al cliente.
    /// </summary>
    public async Task<ConsumoMaterialResponseDto> RegistrarSalidaMaterialAsync(RegistrarSalidaMaterialRequestDto dto)
    {
        if (dto.OperacionId <= 0)
            throw new InvalidOperationException("Debe especificar un proyecto válido.");

        if (dto.AlmacenId <= 0)
            throw new InvalidOperationException("Debe especificar una pieza de almacén válida.");

        if (dto.Cantidad <= 0)
            throw new InvalidOperationException("La cantidad debe ser mayor a cero.");

        var operacion = await _operacionRepo.GetByIdAsync(dto.OperacionId);
        if (operacion == null)
            throw new InvalidOperationException($"El proyecto #{dto.OperacionId} no existe.");

        var pieza = await _almacenRepo.GetByIdAsync(dto.AlmacenId);
        if (pieza == null)
            throw new InvalidOperationException($"La pieza #{dto.AlmacenId} no existe en almacén.");

        int stockActual = pieza.CantidadStock ?? 0;
        if (stockActual < dto.Cantidad)
        {
            throw new InvalidOperationException($"Stock insuficiente para '{pieza.NombrePieza}'. Disponible en almacén: {stockActual}, Solicitado: {dto.Cantidad}.");
        }

        // 1. Descontar del inventario
        int nuevoStock = stockActual - dto.Cantidad;
        await _almacenRepo.UpdateAsync(pieza.IdAlmacen, new CreateAlmacenDto
        {
            NombrePieza = pieza.NombrePieza,
            CantidadStock = nuevoStock,
            CostoPiezas = pieza.CostoPiezas
        });

        // 2. Registrar la salida en SOLICITUD_ALMACEN
        var fechaActual = DateTime.UtcNow;
        var solicitudCreada = await _solicitudAlmacenRepo.CreateAsync(new CreateSolicitudAlmacenDto
        {
            AlmacenId = pieza.IdAlmacen,
            OperacionId = dto.OperacionId,
            CantidadSolicitada = dto.Cantidad,
            FechaSolicitud = fechaActual
        });

        // 3. Registrar el movimiento en MOVIMIENTO_ALMACEN (kardex)
        await _movimientoRepo.CreateAsync(new CreateMovimientoAlmacenDto
        {
            AlmacenId = pieza.IdAlmacen,
            CompraId = null,
            SolicitudAlmacenId = solicitudCreada.IdSolicitudAlmacen,
            TipoMovimiento = "Salida",
            Cantidad = dto.Cantidad,
            FechaMovimiento = fechaActual
        });

        // 4. Calcular el monto a cobrar por el material
        decimal costoUnitario = pieza.CostoPiezas ?? 0m;
        decimal totalCobro = costoUnitario * dto.Cantidad;

        return new ConsumoMaterialResponseDto
        {
            IdSolicitudAlmacen = solicitudCreada.IdSolicitudAlmacen,
            OperacionId = dto.OperacionId,
            IdAlmacen = pieza.IdAlmacen,
            NombrePieza = pieza.NombrePieza,
            CantidadConsumida = dto.Cantidad,
            CostoUnitario = costoUnitario,
            TotalACobrar = totalCobro,
            StockRestante = nuevoStock,
            FechaConsumo = fechaActual
        };
    }

    /// <summary>
    /// Consulta el reporte de contabilidad de todos los materiales consumidos por un proyecto con el desglose a cobrar.
    /// </summary>
    public async Task<IEnumerable<ConsumoMaterialResponseDto>> GetConsumoMaterialPorProyectoAsync(int idProyecto)
    {
        const string query = @"
            SELECT 
                sa.""id_solicitud_almacen"" AS ""IdSolicitudAlmacen"",
                sa.""operacion_id"" AS ""OperacionId"",
                a.""id_almacen"" AS ""IdAlmacen"",
                a.""nombrePieza"" AS ""NombrePieza"",
                sa.""cantidadSolicitada"" AS ""CantidadConsumida"",
                COALESCE(a.""costoPiezas"", 0) AS ""CostoUnitario"",
                (sa.""cantidadSolicitada"" * COALESCE(a.""costoPiezas"", 0)) AS ""TotalACobrar"",
                a.""cantidadStock"" AS ""StockRestante"",
                sa.""fechaSolicitud"" AS ""FechaConsumo""
            FROM SOLICITUD_ALMACEN sa
            INNER JOIN ALMACEN a ON sa.""almacen_id"" = a.""id_almacen""
            WHERE sa.""operacion_id"" = @IdProyecto
            ORDER BY sa.""id_solicitud_almacen"" DESC;";

        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<ConsumoMaterialResponseDto>(query, new { IdProyecto = idProyecto });
    }
}
