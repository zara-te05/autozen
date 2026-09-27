using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProveedorController : ControllerBase
{
    private readonly IProveedorRepository _proveedorRepository;

    public ProveedorController(IProveedorRepository repository)
    {
        _proveedorRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Proveedor>>> GetAll()
    {
        var items = await _proveedorRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Proveedor>> GetById(int id)
    {
        var item = await _proveedorRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "Proveedor no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<Proveedor>> Create([FromBody] CreateProveedorDto dto)
    {
        var created = await _proveedorRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdProveedor }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateProveedorDto dto)
    {
        var updated = await _proveedorRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "Proveedor no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _proveedorRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "Proveedor no encontrado para eliminar." });
        }
        return NoContent();
    }
}
