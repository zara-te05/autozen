using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class EquipoAlmacenController : ControllerBase
{
    private readonly IEquipoAlmacenRepository _equipoalmacenRepository;

    public EquipoAlmacenController(IEquipoAlmacenRepository repository)
    {
        _equipoalmacenRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<EquipoAlmacen>>> GetAll()
    {
        var items = await _equipoalmacenRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<EquipoAlmacen>> GetById(int id)
    {
        var item = await _equipoalmacenRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "EquipoAlmacen no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<EquipoAlmacen>> Create([FromBody] CreateEquipoAlmacenDto dto)
    {
        var created = await _equipoalmacenRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdEquipo }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateEquipoAlmacenDto dto)
    {
        var updated = await _equipoalmacenRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "EquipoAlmacen no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _equipoalmacenRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "EquipoAlmacen no encontrado para eliminar." });
        }
        return NoContent();
    }
}
