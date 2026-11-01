using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Dapper;

namespace Autozen.Api.Services;

public class CompraService
{
    private readonly DapperContext _context;
    private readonly ISolicitudCompraRepository _solicitudRepo;
    private readonly ICompraRepository _compraRepo;
    private readonly IOperacionRepository _operacionRepo;

    public CompraService(
        DapperContext context,
        ISolicitudCompraRepository solicitudRepo,
        ICompraRepository compraRepo,
        IOperacionRepository operacionRepo)
    {
        _context = context;
        _solicitudRepo = solicitudRepo;
        _compraRepo = compraRepo;
        _operacionRepo = operacionRepo;
    }

    /// <summary>
    /// Levanta una nueva solicitud de compra vinculada a un proyecto (Operación) y proveedor sugerido.
    /// </summary>
    public async Task<SolicitudCompra> CrearSolicitudCompraAsync(CrearSolicitudCompraRequestDto dto, int? usuarioId)
    {
        if (dto.OperacionId <= 0)
            throw new InvalidOperationException("Debe especificar un ID de proyecto válido.");

        if (string.IsNullOrWhiteSpace(dto.NombrePiezasCotizadas))
            throw new InvalidOperationException("Debe especificar las piezas requeridas.");

        if (dto.CantidadPiezasCotizadas <= 0)
            throw new InvalidOperationException("La cantidad de piezas debe ser mayor a cero.");

        var operacion = await _operacionRepo.GetByIdAsync(dto.OperacionId);
        if (operacion == null)
            throw new InvalidOperationException($"El proyecto #{dto.OperacionId} no existe.");

        var nuevaSolicitud = new CreateSolicitudCompraDto
        {
            OperacionId = dto.OperacionId,
            UsuarioId = usuarioId,
            ProveedorId = dto.ProveedorId,
            NombrePiezasCotizadas = dto.NombrePiezasCotizadas.Trim(),
            CantidadPiezasCotizadas = dto.CantidadPiezasCotizadas,
            FechaSolicitud = DateTime.UtcNow
        };

        return await _solicitudRepo.CreateAsync(nuevaSolicitud);
    }

    /// <summary>
    /// Registra formalmente una Orden de Compra asociada al proyecto y solicitud.
    /// </summary>
    public async Task<OrdenCompraDetalleResponseDto> CrearOrdenCompraAsync(CrearOrdenCompraRequestDto dto)
    {
        if (dto.SolicitudCompraId <= 0 || dto.OperacionId <= 0)
            throw new InvalidOperationException("La solicitud y el proyecto asociado son requeridos.");

        if (string.IsNullOrWhiteSpace(dto.NombrePiezas))
            throw new InvalidOperationException("La descripción de las piezas es requerida.");

        if (dto.CantidadPiezas <= 0)
            throw new InvalidOperationException("La cantidad debe ser mayor a cero.");

        if (dto.CostoPiezas < 0)
            throw new InvalidOperationException("El costo no puede ser negativo.");

        var nuevaCompra = new CreateCompraDto
        {
            SolicitudCompraId = dto.SolicitudCompraId,
            OperacionId = dto.OperacionId,
            NombrePiezas = dto.NombrePiezas.Trim(),
            CantidadPiezas = dto.CantidadPiezas,
            CostoPiezas = dto.CostoPiezas
        };

        var compraCreada = await _compraRepo.CreateAsync(nuevaCompra);
        var detalle = await GetOrdenCompraByIdAsync(compraCreada.IdCompra);

        return detalle ?? throw new InvalidOperationException("Error al recuperar la orden de compra creada.");
    }

    /// <summary>
    /// Lista todas las órdenes de compra con datos de proveedor, vehículo y cálculo de tiempos estimados de entrega.
    /// Exclusivo para el Administrador de Compras y Administración.
    /// </summary>
    /// <summary>
    /// Crea la solicitud y la orden de compra en un solo paso (lo que usa la app).
    /// </summary>
    public async Task<OrdenCompraDetalleResponseDto> CrearOrdenDirectaAsync(CrearOrdenDirectaRequest dto, int? usuarioId)
    {
        var operacion = await _operacionRepo.GetByIdAsync(dto.OperacionId)
            ?? throw new Autozen.Api.Errors.NoEncontradoException($"El proyecto #{dto.OperacionId} no existe.");

        int idCompra = await _context.EnTransaccionAsync(async () =>
        {
            var solicitud = await _solicitudRepo.CreateAsync(new CreateSolicitudCompraDto
            {
                OperacionId = operacion.IdOperacion,
                UsuarioId = usuarioId,
                ProveedorId = dto.ProveedorId,
                NombrePiezasCotizadas = dto.NombrePiezas.Trim(),
                CantidadPiezasCotizadas = dto.CantidadPiezas,
                FechaSolicitud = DateTime.Now
            });
            var compra = await _compraRepo.CreateAsync(new CreateCompraDto
            {
                SolicitudCompraId = solicitud.IdSolicitudCompra,
                OperacionId = operacion.IdOperacion,
                NombrePiezas = dto.NombrePiezas.Trim(),
                CantidadPiezas = dto.CantidadPiezas,
                CostoPiezas = dto.CostoPiezas
            });
            return compra.IdCompra;
        });

        return await GetOrdenCompraByIdAsync(idCompra)
            ?? throw new InvalidOperationException("Error al recuperar la orden de compra creada.");
    }

    public async Task<IEnumerable<OrdenCompraDetalleResponseDto>> GetAllOrdenesCompraAsync()
    {
        const string query = @"
            SELECT 
                c.""id_compra"" AS ""IdCompra"",
                c.""solicitud_compra_id"" AS ""SolicitudCompraId"",
                c.""operacion_id"" AS ""OperacionId"",
                c.""nombrePiezas"" AS ""NombrePiezas"",
                c.""cantidadPiezas"" AS ""CantidadPiezas"",
                c.""costoPiezas"" AS ""CostoPiezas"",
                cam.""placas"" AS ""PlacasCamion"",
                COALESCE(NULLIF(cam.nombre, ''), TRIM(COALESCE(cam.""marca"", '') || ' ' || COALESCE(cam.""modelo"", ''))) AS ""MarcaModeloCamion"",
                COALESCE(o.aseguradora, TRIM(COALESCE(cli.""nombre"", '') || ' ' || COALESCE(cli.""apellido"", ''))) AS ""NombreCliente"",
                p.""id_proveedor"" AS ""ProveedorId"",
                p.""nombreProveedor"" AS ""NombreProveedor"",
                p.""contacto"" AS ""ContactoProveedor"",
                p.""tiempoEntregaPromedioDias"" AS ""TiempoEntregaPromedioDias"",
                sc.""fechaSolicitud"" AS ""FechaSolicitud"",
                u.""nombre"" AS ""SolicitadoPor""
            FROM COMPRA c
            INNER JOIN SOLICITUD_COMPRA sc ON c.""solicitud_compra_id"" = sc.""id_solicitud_compra""
            INNER JOIN OPERACIONES o ON c.""operacion_id"" = o.""id_operacion""
            INNER JOIN CAMION cam ON o.""camion_id"" = cam.""id_camion""
            LEFT JOIN CLIENTE cli ON cam.""cliente_id"" = cli.""id_cliente""
            LEFT JOIN PROVEEDOR p ON sc.""proveedor_id"" = p.""id_proveedor""
            LEFT JOIN USUARIO u ON sc.""usuario_id"" = u.""id_usuario""
            ORDER BY c.""id_compra"" DESC;";

        var lista = await _context.RunAsync((connection, tx) => connection.QueryAsync<dynamic>(query, transaction: tx));

        return lista.Select(MapearADetalle);
    }

    /// <summary>
    /// Consulta las órdenes de compra asociadas a un proyecto específico.
    /// </summary>
    public async Task<IEnumerable<OrdenCompraDetalleResponseDto>> GetOrdenesPorProyectoAsync(int idProyecto)
    {
        const string query = @"
            SELECT 
                c.""id_compra"" AS ""IdCompra"",
                c.""solicitud_compra_id"" AS ""SolicitudCompraId"",
                c.""operacion_id"" AS ""OperacionId"",
                c.""nombrePiezas"" AS ""NombrePiezas"",
                c.""cantidadPiezas"" AS ""CantidadPiezas"",
                c.""costoPiezas"" AS ""CostoPiezas"",
                cam.""placas"" AS ""PlacasCamion"",
                COALESCE(NULLIF(cam.nombre, ''), TRIM(COALESCE(cam.""marca"", '') || ' ' || COALESCE(cam.""modelo"", ''))) AS ""MarcaModeloCamion"",
                COALESCE(o.aseguradora, TRIM(COALESCE(cli.""nombre"", '') || ' ' || COALESCE(cli.""apellido"", ''))) AS ""NombreCliente"",
                p.""id_proveedor"" AS ""ProveedorId"",
                p.""nombreProveedor"" AS ""NombreProveedor"",
                p.""contacto"" AS ""ContactoProveedor"",
                p.""tiempoEntregaPromedioDias"" AS ""TiempoEntregaPromedioDias"",
                sc.""fechaSolicitud"" AS ""FechaSolicitud"",
                u.""nombre"" AS ""SolicitadoPor""
            FROM COMPRA c
            INNER JOIN SOLICITUD_COMPRA sc ON c.""solicitud_compra_id"" = sc.""id_solicitud_compra""
            INNER JOIN OPERACIONES o ON c.""operacion_id"" = o.""id_operacion""
            INNER JOIN CAMION cam ON o.""camion_id"" = cam.""id_camion""
            LEFT JOIN CLIENTE cli ON cam.""cliente_id"" = cli.""id_cliente""
            LEFT JOIN PROVEEDOR p ON sc.""proveedor_id"" = p.""id_proveedor""
            LEFT JOIN USUARIO u ON sc.""usuario_id"" = u.""id_usuario""
            WHERE c.""operacion_id"" = @IdProyecto
            ORDER BY c.""id_compra"" DESC;";

        var lista = await _context.RunAsync((connection, tx) => connection.QueryAsync<dynamic>(query, new { IdProyecto = idProyecto }, transaction: tx));

        return lista.Select(MapearADetalle);
    }

    /// <summary>
    /// Obtiene el detalle completo de una orden de compra por su ID.
    /// </summary>
    public async Task<OrdenCompraDetalleResponseDto?> GetOrdenCompraByIdAsync(int idCompra)
    {
        const string query = @"
            SELECT 
                c.""id_compra"" AS ""IdCompra"",
                c.""solicitud_compra_id"" AS ""SolicitudCompraId"",
                c.""operacion_id"" AS ""OperacionId"",
                c.""nombrePiezas"" AS ""NombrePiezas"",
                c.""cantidadPiezas"" AS ""CantidadPiezas"",
                c.""costoPiezas"" AS ""CostoPiezas"",
                cam.""placas"" AS ""PlacasCamion"",
                COALESCE(NULLIF(cam.nombre, ''), TRIM(COALESCE(cam.""marca"", '') || ' ' || COALESCE(cam.""modelo"", ''))) AS ""MarcaModeloCamion"",
                COALESCE(o.aseguradora, TRIM(COALESCE(cli.""nombre"", '') || ' ' || COALESCE(cli.""apellido"", ''))) AS ""NombreCliente"",
                p.""id_proveedor"" AS ""ProveedorId"",
                p.""nombreProveedor"" AS ""NombreProveedor"",
                p.""contacto"" AS ""ContactoProveedor"",
                p.""tiempoEntregaPromedioDias"" AS ""TiempoEntregaPromedioDias"",
                sc.""fechaSolicitud"" AS ""FechaSolicitud"",
                u.""nombre"" AS ""SolicitadoPor""
            FROM COMPRA c
            INNER JOIN SOLICITUD_COMPRA sc ON c.""solicitud_compra_id"" = sc.""id_solicitud_compra""
            INNER JOIN OPERACIONES o ON c.""operacion_id"" = o.""id_operacion""
            INNER JOIN CAMION cam ON o.""camion_id"" = cam.""id_camion""
            LEFT JOIN CLIENTE cli ON cam.""cliente_id"" = cli.""id_cliente""
            LEFT JOIN PROVEEDOR p ON sc.""proveedor_id"" = p.""id_proveedor""
            LEFT JOIN USUARIO u ON sc.""usuario_id"" = u.""id_usuario""
            WHERE c.""id_compra"" = @Id;";

        var item = await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<dynamic>(query, new { Id = idCompra }, transaction: tx));

        return item == null ? null : MapearADetalle(item);
    }

    /// <summary>
    /// Edita las piezas, cantidades o costos de una orden de compra.
    /// </summary>
    public async Task<bool> EditarOrdenCompraAsync(int idCompra, EditarOrdenCompraRequestDto dto)
    {
        var compraExistente = await _compraRepo.GetByIdAsync(idCompra);
        if (compraExistente == null)
            return false;

        return await _compraRepo.UpdateAsync(idCompra, new CreateCompraDto
        {
            SolicitudCompraId = compraExistente.SolicitudCompraId,
            OperacionId = compraExistente.OperacionId,
            NombrePiezas = string.IsNullOrWhiteSpace(dto.NombrePiezas) ? compraExistente.NombrePiezas : dto.NombrePiezas.Trim(),
            CantidadPiezas = dto.CantidadPiezas > 0 ? dto.CantidadPiezas : compraExistente.CantidadPiezas,
            CostoPiezas = dto.CostoPiezas >= 0 ? dto.CostoPiezas : compraExistente.CostoPiezas
        });
    }

    /// <summary>
    /// Elimina una orden de compra.
    /// </summary>
    public async Task<bool> EliminarOrdenCompraAsync(int idCompra)
    {
        return await _compraRepo.DeleteAsync(idCompra);
    }

    private static OrdenCompraDetalleResponseDto MapearADetalle(dynamic item)
    {
        DateTime fechaSolicitud = (DateTime)item.FechaSolicitud;
        int diasPromedio = item.TiempoEntregaPromedioDias != null ? (int)item.TiempoEntregaPromedioDias : 3;
        DateTime fechaEstimada = fechaSolicitud.AddDays(diasPromedio);

        return new OrdenCompraDetalleResponseDto
        {
            IdCompra = (int)item.IdCompra,
            SolicitudCompraId = (int)item.SolicitudCompraId,
            OperacionId = (int)item.OperacionId,
            NombrePiezas = (string)item.NombrePiezas,
            CantidadPiezas = item.CantidadPiezas != null ? (int)item.CantidadPiezas : 1,
            CostoPiezas = item.CostoPiezas != null ? (decimal)item.CostoPiezas : 0m,
            PlacasCamion = (string)item.PlacasCamion,
            MarcaModeloCamion = (string?)item.MarcaModeloCamion,
            NombreCliente = (string?)item.NombreCliente,
            ProveedorId = (int?)item.ProveedorId,
            NombreProveedor = (string?)item.NombreProveedor,
            ContactoProveedor = (string?)item.ContactoProveedor,
            TiempoEntregaPromedioDias = diasPromedio,
            FechaSolicitud = fechaSolicitud,
            FechaEstimadaEntrega = fechaEstimada,
            SolicitadoPor = (string?)item.SolicitadoPor
        };
    }
}
