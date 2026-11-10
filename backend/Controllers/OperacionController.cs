using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = Lectura.Proyectos)] // Leer: Admin, jefes y usuarios del área de Proyectos (y Evaluación). Escribir: según cada acción
public class OperacionController : ControllerBase
{
    private readonly IOperacionRepository _operacionRepository;

    public OperacionController(IOperacionRepository repository)
    {
        _operacionRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Operacion>>> GetAll()
    {
        var items = await _operacionRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Operacion>> GetById(int id)
    {
        var item = await _operacionRepository.GetByIdAsync(id);
        if (item is null)
        {
            return Problem(detail: "Operacion no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<ActionResult<Operacion>> Create([FromBody] CreateOperacionDto dto)
    {
        var created = await _operacionRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdOperacion }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateOperacionDto dto)
    {
        var updated = await _operacionRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "Operacion no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _operacionRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "Operacion no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
