using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ValeSalidaController : ControllerBase
{
    private readonly IValeSalidaRepository _valesalidaRepository;

    public ValeSalidaController(IValeSalidaRepository repository)
    {
        _valesalidaRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ValeSalida>>> GetAll()
    {
        var items = await _valesalidaRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ValeSalida>> GetById(int id)
    {
        var item = await _valesalidaRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "ValeSalida no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<ValeSalida>> Create([FromBody] CreateValeSalidaDto dto)
    {
        var created = await _valesalidaRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdVale }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateValeSalidaDto dto)
    {
        var updated = await _valesalidaRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "ValeSalida no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _valesalidaRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "ValeSalida no encontrado para eliminar." });
        }
        return NoContent();
    }
}
