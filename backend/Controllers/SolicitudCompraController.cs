using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class SolicitudCompraController : ControllerBase
{
    private readonly ISolicitudCompraRepository _solicitudcompraRepository;

    public SolicitudCompraController(ISolicitudCompraRepository repository)
    {
        _solicitudcompraRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SolicitudCompra>>> GetAll()
    {
        var items = await _solicitudcompraRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SolicitudCompra>> GetById(int id)
    {
        var item = await _solicitudcompraRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "SolicitudCompra no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<SolicitudCompra>> Create([FromBody] CreateSolicitudCompraDto dto)
    {
        var created = await _solicitudcompraRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdSolicitudCompra }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateSolicitudCompraDto dto)
    {
        var updated = await _solicitudcompraRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "SolicitudCompra no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _solicitudcompraRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "SolicitudCompra no encontrado para eliminar." });
        }
        return NoContent();
    }
}
