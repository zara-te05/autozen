using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class FacturaController : ControllerBase
{
    private readonly IFacturaRepository _facturaRepository;

    public FacturaController(IFacturaRepository repository)
    {
        _facturaRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Factura>>> GetAll()
    {
        var items = await _facturaRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Factura>> GetById(int id)
    {
        var item = await _facturaRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "Factura no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<Factura>> Create([FromBody] CreateFacturaDto dto)
    {
        var created = await _facturaRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdFactura }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateFacturaDto dto)
    {
        var updated = await _facturaRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "Factura no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _facturaRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "Factura no encontrado para eliminar." });
        }
        return NoContent();
    }
}
