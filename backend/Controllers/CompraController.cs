using System.Security.Claims;
using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Autenticación obligatoria
public class CompraController : ControllerBase
{
    private readonly CompraService _compraService;
    private readonly CompraPdfService _pdfService;

    public CompraController(CompraService compraService, CompraPdfService pdfService)
    {
        _compraService = compraService;
        _pdfService = pdfService;
    }

    /// <summary>
    /// Lista todas las órdenes de compra con cálculo de tiempos estimados de entrega y proveedor.
    /// Lectura para cualquier usuario autenticado (los jefes pueden consultar otros departamentos).
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var compras = await _compraService.GetAllOrdenesCompraAsync();
        return Ok(compras);
    }

    /// <summary>
    /// Lista las órdenes de compra asociadas a un proyecto en específico.
    /// Accesible por el taller y compras para monitoreo de avances.
    /// </summary>
    [HttpGet("proyecto/{idProyecto}")]
    public async Task<IActionResult> GetByProyecto(int idProyecto)
    {
        var compras = await _compraService.GetOrdenesPorProyectoAsync(idProyecto);
        return Ok(compras);
    }

    /// <summary>
    /// Obtiene el detalle técnico completo de una orden de compra por ID.
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var compra = await _compraService.GetOrdenCompraByIdAsync(id);
        return compra == null
            ? Problem(detail: $"La orden de compra #{id} no existe.", statusCode: StatusCodes.Status404NotFound)
            : Ok(compra);
    }

    /// <summary>
    /// Levanta una solicitud de compra asignada a un proyecto (Operación).
    /// Permitido para Compras, Líderes de Proyecto y Administradores.
    /// </summary>
    [HttpPost("solicitud")]
    [Authorize(Roles = "Admin,Compras_Admin,Proyecto_Lider")]
    public async Task<IActionResult> CrearSolicitud([FromBody] CrearSolicitudCompraRequestDto dto)
    {
        try
        {
            int? usuarioId = null;
            var subClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(subClaim, out int uid))
            {
                usuarioId = uid;
            }

            var solicitud = await _compraService.CrearSolicitudCompraAsync(dto, usuarioId);
            return Ok(new
            {
                message = "Solicitud de compra levantada con éxito.",
                solicitud
            });
        }
        catch (InvalidOperationException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    /// <summary>
    /// Registra formalmente una orden de compra en el sistema.
    /// Exclusivo para personal de Compras y Administración.
    /// </summary>
    /// <summary>
    /// Crea solicitud y orden de compra en un solo paso.
    /// </summary>
    [HttpPost("orden-directa")]
    [Authorize(Roles = Edicion.Compras)]
    public async Task<IActionResult> CrearOrdenDirecta([FromBody] CrearOrdenDirectaRequest dto)
    {
        var valor = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        var orden = await _compraService.CrearOrdenDirectaAsync(dto, int.TryParse(valor, out var id) ? id : null);
        return CreatedAtAction(nameof(GetById), new { id = orden.IdCompra }, orden);
    }

    [HttpPost("orden")]
    [Authorize(Roles = "Admin,Compras_Admin")]
    public async Task<IActionResult> CrearOrden([FromBody] CrearOrdenCompraRequestDto dto)
    {
        try
        {
            var orden = await _compraService.CrearOrdenCompraAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = orden.IdCompra }, orden);
        }
        catch (InvalidOperationException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    /// <summary>
    /// Edita las piezas, cantidades o costos de una orden de compra.
    /// </summary>
    [HttpPut("orden/{id}")]
    [Authorize(Roles = "Admin,Compras_Admin")]
    public async Task<IActionResult> EditarOrden(int id, [FromBody] EditarOrdenCompraRequestDto dto)
    {
        var actualizado = await _compraService.EditarOrdenCompraAsync(id, dto);
        if (!actualizado)
        {
            return Problem(detail: $"Orden de compra #{id} no encontrada para editar.", statusCode: StatusCodes.Status404NotFound);
        }

        return NoContent();
    }

    /// <summary>
    /// Elimina una orden de compra del sistema.
    /// </summary>
    [HttpDelete("orden/{id}")]
    [Authorize(Roles = "Admin,Compras_Admin")]
    public async Task<IActionResult> EliminarOrden(int id)
    {
        var eliminado = await _compraService.EliminarOrdenCompraAsync(id);
        if (!eliminado)
        {
            return Problem(detail: $"Orden de compra #{id} no encontrada para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }

        return NoContent();
    }

    /// <summary>
    /// Genera y descarga el documento PDF oficial de la orden de compra con todos los datos del proyecto y proveedor.
    /// </summary>
    [HttpGet("orden/{id}/pdf")]
    public async Task<IActionResult> DescargarPdf(int id)
    {
        var orden = await _compraService.GetOrdenCompraByIdAsync(id);
        if (orden == null)
        {
            return Problem(detail: $"La orden de compra #{id} no existe.", statusCode: StatusCodes.Status404NotFound);
        }

        byte[] pdfBytes = _pdfService.GenerarOrdenCompraPdf(orden);
        string nombreArchivo = $"OrdenCompra_{orden.IdCompra:D5}_{orden.PlacasCamion}.pdf";

        return File(pdfBytes, "application/pdf", nombreArchivo);
    }
}
