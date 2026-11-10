using System.Security.Claims;
using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

/// <summary>
/// Tablero de inicio: entregas de la semana, coordinación operativa del día y anuncios.
/// Cualquier usuario autenticado lo lee; solo el Admin crea, edita y elimina.
/// Las entregas de la semana salen de los proyectos existentes; el Admin puede agregar entregas manuales o quitar proyectos.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TableroController : ControllerBase
{
    private readonly TableroService _servicio;

    public TableroController(TableroService servicio) => _servicio = servicio;

    private string? Usuario => User.FindFirstValue("nombre") is { Length: > 0 } nombre ? nombre : User.Identity?.Name;

    [HttpGet]
    public async Task<ActionResult<TableroDto>> Obtener() => Ok(await _servicio.ObtenerAsync(User.IsInRole(Roles.Admin)));

    // ---------- Entregas de la semana ----------

    [HttpPost("entregas")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<EntregaSemanaDto>> CrearEntrega([FromBody] EntregaSemanaDto dto) =>
        Ok(await _servicio.GuardarEntregaAsync(null, dto, Usuario));

    [HttpPut("entregas/{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<EntregaSemanaDto>> EditarEntrega(int id, [FromBody] EntregaSemanaDto dto) =>
        Ok(await _servicio.GuardarEntregaAsync(id, dto, Usuario));

    [HttpDelete("entregas/{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> EliminarEntrega(int id)
    {
        await _servicio.EliminarEntregaAsync(id);
        return NoContent();
    }

    /// <summary>Quita del tablero un proyecto que está por entregarse.</summary>
    [HttpPost("entregas/proyecto/{proyectoId:int}/ocultar")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> OcultarProyecto(int proyectoId)
    {
        await _servicio.OcultarProyectoAsync(proyectoId, Usuario);
        return NoContent();
    }

    /// <summary>Regresa al tablero un proyecto que se había quitado.</summary>
    [HttpDelete("entregas/proyecto/{proyectoId:int}/ocultar")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> MostrarProyecto(int proyectoId)
    {
        await _servicio.MostrarProyectoAsync(proyectoId);
        return NoContent();
    }

    // ---------- Coordinación operativa del día ----------

    [HttpPost("coordinacion")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<CoordinacionDto>> CrearCoordinacion([FromBody] CoordinacionDto dto) =>
        Ok(await _servicio.GuardarCoordinacionAsync(null, dto, Usuario));

    [HttpPut("coordinacion/{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<CoordinacionDto>> EditarCoordinacion(int id, [FromBody] CoordinacionDto dto) =>
        Ok(await _servicio.GuardarCoordinacionAsync(id, dto, Usuario));

    [HttpDelete("coordinacion/{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> EliminarCoordinacion(int id)
    {
        await _servicio.EliminarCoordinacionAsync(id);
        return NoContent();
    }

    // ---------- Anuncios ----------

    [HttpPost("anuncios")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<AnuncioDto>> CrearAnuncio([FromBody] AnuncioDto dto) =>
        Ok(await _servicio.GuardarAnuncioAsync(null, dto, Usuario));

    [HttpPut("anuncios/{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<AnuncioDto>> EditarAnuncio(int id, [FromBody] AnuncioDto dto) =>
        Ok(await _servicio.GuardarAnuncioAsync(id, dto, Usuario));

    [HttpDelete("anuncios/{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> EliminarAnuncio(int id)
    {
        await _servicio.EliminarAnuncioAsync(id);
        return NoContent();
    }
}
