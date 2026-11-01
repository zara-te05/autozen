using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Leer: cualquier usuario autenticado. Escribir: Admin y jefe de Compras
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
            return Problem(detail: "Proveedor no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Compras)]
    public async Task<ActionResult<Proveedor>> Create([FromBody] CreateProveedorDto dto)
    {
        var created = await _proveedorRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdProveedor }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Compras)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateProveedorDto dto)
    {
        var updated = await _proveedorRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "Proveedor no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Compras)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _proveedorRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "Proveedor no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
