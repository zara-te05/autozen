using System.Security.Claims;
using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

/// <summary>Avisos de eventos para el rol del usuario (proyecto nuevo/editado, compra solicitada/aprobada).</summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotificacionController : ControllerBase
{
    private readonly NotificacionService _servicio;

    public NotificacionController(NotificacionService servicio) => _servicio = servicio;

    [HttpGet]
    public async Task<ActionResult<List<AvisoDto>>> Listar() =>
        Ok(await _servicio.ListarAsync(User.FindFirstValue(ClaimTypes.Role) ?? Roles.Usuario));
}
