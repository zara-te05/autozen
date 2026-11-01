using System.Security.Claims;
using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

/// <summary>Solicitudes de compra de los proyectos y la orden de compra que genera Compras.</summary>
[ApiController]
[Route("api/Compra/solicitudes")]
[Authorize]
public class SolicitudesCompraController : ControllerBase
{
    private readonly SolicitudesCompraService _servicio;

    public SolicitudesCompraController(SolicitudesCompraService servicio) => _servicio = servicio;

    [HttpGet]
    public async Task<ActionResult<List<SolicitudCompraAppDto>>> Listar() => Ok(await _servicio.ListarAsync());

    [HttpPost]
    [Authorize(Roles = Edicion.SolicitarCompra)]
    public async Task<ActionResult<SolicitudCompraAppDto>> Crear([FromBody] CrearSolicitudAppRequest request)
    {
        var valor = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        var nombre = User.FindFirstValue("nombre");
        return Ok(await _servicio.CrearAsync(request, int.TryParse(valor, out var id) ? id : null, string.IsNullOrWhiteSpace(nombre) ? User.Identity?.Name : nombre));
    }

    /// <summary>Compras completa la orden de compra y aprueba la solicitud.</summary>
    [HttpPost("{id:int}/aprobar")]
    [Authorize(Roles = Edicion.Compras)]
    public async Task<ActionResult<SolicitudCompraAppDto>> Aprobar(int id, [FromBody] AprobarSolicitudRequest request) =>
        Ok(await _servicio.AprobarAsync(id, request));

    [HttpPost("{id:int}/rechazar")]
    [Authorize(Roles = Edicion.Compras)]
    public async Task<ActionResult<SolicitudCompraAppDto>> Rechazar(int id, [FromBody] RechazarSolicitudRequest request) =>
        Ok(await _servicio.RechazarAsync(id, request.Motivo));

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Edicion.SolicitarCompra)]
    public async Task<IActionResult> Eliminar(int id)
    {
        await _servicio.EliminarAsync(id);
        return NoContent();
    }
}
