using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AlmacenController : ControllerBase
{
    private readonly IAlmacenRepository _almacenRepository;

    public AlmacenController(IAlmacenRepository repository)
    {
        _almacenRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Almacen>>> GetAll()
    {
        var items = await _almacenRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Almacen>> GetById(int id)
    {
        var item = await _almacenRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "Almacen no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<Almacen>> Create([FromBody] CreateAlmacenDto dto)
    {
        var created = await _almacenRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdAlmacen }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateAlmacenDto dto)
    {
        var updated = await _almacenRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "Almacen no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _almacenRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "Almacen no encontrado para eliminar." });
        }
        return NoContent();
    }
}
