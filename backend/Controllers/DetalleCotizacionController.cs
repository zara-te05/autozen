using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Leer: cualquier usuario autenticado. Escribir: Admin y jefe de Proyectos
public class DetalleCotizacionController : ControllerBase
{
    private readonly IDetalleCotizacionRepository _detallecotizacionRepository;

    public DetalleCotizacionController(IDetalleCotizacionRepository repository)
    {
        _detallecotizacionRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<DetalleCotizacion>>> GetAll()
    {
        var items = await _detallecotizacionRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<DetalleCotizacion>> GetById(int id)
    {
        var item = await _detallecotizacionRepository.GetByIdAsync(id);
        if (item is null)
        {
            return Problem(detail: "DetalleCotizacion no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<ActionResult<DetalleCotizacion>> Create([FromBody] CreateDetalleCotizacionDto dto)
    {
        var created = await _detallecotizacionRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdDetalleCotizacion }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateDetalleCotizacionDto dto)
    {
        var updated = await _detallecotizacionRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "DetalleCotizacion no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _detallecotizacionRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "DetalleCotizacion no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
