using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
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
            return NotFound(new { message = "Camion no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<Camion>> Create([FromBody] CreateCamionDto dto)
    {
        var created = await _camionRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdCamion }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateCamionDto dto)
    {
        var updated = await _camionRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "Camion no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _camionRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "Camion no encontrado para eliminar." });
        }
        return NoContent();
    }
}
