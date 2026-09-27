using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SolicitudAlmacenController : ControllerBase
{
    private readonly ISolicitudAlmacenRepository _solicitudalmacenRepository;

    public SolicitudAlmacenController(ISolicitudAlmacenRepository repository)
    {
        _solicitudalmacenRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SolicitudAlmacen>>> GetAll()
    {
        var items = await _solicitudalmacenRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SolicitudAlmacen>> GetById(int id)
    {
        var item = await _solicitudalmacenRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "SolicitudAlmacen no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<SolicitudAlmacen>> Create([FromBody] CreateSolicitudAlmacenDto dto)
    {
        var created = await _solicitudalmacenRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdSolicitudAlmacen }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateSolicitudAlmacenDto dto)
    {
        var updated = await _solicitudalmacenRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "SolicitudAlmacen no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _solicitudalmacenRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "SolicitudAlmacen no encontrado para eliminar." });
        }
        return NoContent();
    }
}
