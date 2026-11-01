using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Leer: cualquier usuario autenticado. Escribir: Admin y jefe de Almacén
public class EquipoAlmacenController : ControllerBase
{
    private readonly IEquipoAlmacenRepository _equipoalmacenRepository;

    public EquipoAlmacenController(IEquipoAlmacenRepository repository)
    {
        _equipoalmacenRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<EquipoAlmacen>>> GetAll()
    {
        var items = await _equipoalmacenRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<EquipoAlmacen>> GetById(int id)
    {
        var item = await _equipoalmacenRepository.GetByIdAsync(id);
        if (item is null)
        {
            return Problem(detail: "EquipoAlmacen no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<ActionResult<EquipoAlmacen>> Create([FromBody] CreateEquipoAlmacenDto dto)
    {
        var created = await _equipoalmacenRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdEquipo }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateEquipoAlmacenDto dto)
    {
        var updated = await _equipoalmacenRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "EquipoAlmacen no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _equipoalmacenRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "EquipoAlmacen no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
