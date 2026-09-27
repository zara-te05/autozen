using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CompraController : ControllerBase
{
    private readonly ICompraRepository _compraRepository;

    public CompraController(ICompraRepository repository)
    {
        _compraRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Compra>>> GetAll()
    {
        var items = await _compraRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Compra>> GetById(int id)
    {
        var item = await _compraRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "Compra no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<Compra>> Create([FromBody] CreateCompraDto dto)
    {
        var created = await _compraRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdCompra }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateCompraDto dto)
    {
        var updated = await _compraRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "Compra no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _compraRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "Compra no encontrado para eliminar." });
        }
        return NoContent();
    }
}
