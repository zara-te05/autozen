using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Leer: cualquier usuario autenticado. Escribir: Admin y jefe de Evaluación
public class CamionController : ControllerBase
{
    private readonly ICamionRepository _camionRepository;

    public CamionController(ICamionRepository repository)
    {
        _camionRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Camion>>> GetAll()
    {
        var items = await _camionRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Camion>> GetById(int id)
    {
        var item = await _camionRepository.GetByIdAsync(id);
        if (item is null)
        {
            return Problem(detail: "Camion no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Evaluacion)]
    public async Task<ActionResult<Camion>> Create([FromBody] CreateCamionDto dto)
    {
        var created = await _camionRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdCamion }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Evaluacion)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateCamionDto dto)
    {
        var updated = await _camionRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "Camion no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Evaluacion)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _camionRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "Camion no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
