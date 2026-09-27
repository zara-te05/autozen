using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DevolucionProveedorController : ControllerBase
{
    private readonly IDevolucionProveedorRepository _devolucionproveedorRepository;

    public DevolucionProveedorController(IDevolucionProveedorRepository repository)
    {
        _devolucionproveedorRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<DevolucionProveedor>>> GetAll()
    {
        var items = await _devolucionproveedorRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<DevolucionProveedor>> GetById(int id)
    {
        var item = await _devolucionproveedorRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "DevolucionProveedor no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<DevolucionProveedor>> Create([FromBody] CreateDevolucionProveedorDto dto)
    {
        var created = await _devolucionproveedorRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdDevolucion }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateDevolucionProveedorDto dto)
    {
        var updated = await _devolucionproveedorRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "DevolucionProveedor no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _devolucionproveedorRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "DevolucionProveedor no encontrado para eliminar." });
        }
        return NoContent();
    }
}
