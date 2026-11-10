using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = Lectura.Proyectos)] // Leer: Admin, jefes y usuarios del área de Proyectos (y Evaluación). Escribir: según cada acción
public class CotizacionController : ControllerBase
{
    private readonly ICotizacionRepository _cotizacionRepository;

    public CotizacionController(ICotizacionRepository repository)
    {
        _cotizacionRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Cotizacion>>> GetAll()
    {
        var items = await _cotizacionRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Cotizacion>> GetById(int id)
    {
        var item = await _cotizacionRepository.GetByIdAsync(id);
        if (item is null)
        {
            return Problem(detail: "Cotizacion no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<ActionResult<Cotizacion>> Create([FromBody] CreateCotizacionDto dto)
    {
        var created = await _cotizacionRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdCotizacion }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateCotizacionDto dto)
    {
        var updated = await _cotizacionRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "Cotizacion no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _cotizacionRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "Cotizacion no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
