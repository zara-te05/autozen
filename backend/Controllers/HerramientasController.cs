using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

/// <summary>Préstamos de herramienta: salen del almacén y deben regresar.</summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = Lectura.Almacen)] // Leer: Admin, jefes y usuarios del área de Almacén. Escribir: según cada acción
public class HerramientasController : ControllerBase
{
    private readonly HerramientasService _servicio;

    public HerramientasController(HerramientasService servicio) => _servicio = servicio;

    [HttpGet]
    public async Task<ActionResult<List<ValeHerramientaDto>>> Listar([FromQuery] int? proyectoId) => Ok(await _servicio.ListarAsync(proyectoId));

    [HttpPost("prestar")]
    [Authorize(Roles = Edicion.ValesAlmacen)]
    public async Task<ActionResult<ValeHerramientaDto>> Prestar([FromBody] PrestarHerramientaRequest request) =>
        Ok(await _servicio.PrestarAsync(request));

    [HttpPost("{id:int}/devolver")]
    [Authorize(Roles = Edicion.ValesAlmacen)]
    public async Task<ActionResult<ValeHerramientaDto>> Devolver(int id, [FromBody] DevolverHerramientaRequest request) =>
        Ok(await _servicio.DevolverAsync(id, request.Estado));

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Edicion.ValesAlmacen)]
    public async Task<IActionResult> Eliminar(int id)
    {
        await _servicio.EliminarAsync(id);
        return NoContent();
    }
}
