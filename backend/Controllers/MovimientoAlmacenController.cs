using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Leer: cualquier usuario autenticado. Escribir: Admin y jefe de Almacén
public class MovimientoAlmacenController : ControllerBase
{
    private readonly IMovimientoAlmacenRepository _movimientoalmacenRepository;

    public MovimientoAlmacenController(IMovimientoAlmacenRepository repository)
    {
        _movimientoalmacenRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<MovimientoAlmacen>>> GetAll()
    {
        var items = await _movimientoalmacenRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<MovimientoAlmacen>> GetById(int id)
    {
        var item = await _movimientoalmacenRepository.GetByIdAsync(id);
        if (item is null)
        {
            return Problem(detail: "MovimientoAlmacen no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<ActionResult<MovimientoAlmacen>> Create([FromBody] CreateMovimientoAlmacenDto dto)
    {
        var created = await _movimientoalmacenRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdMovimiento }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateMovimientoAlmacenDto dto)
    {
        var updated = await _movimientoalmacenRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "MovimientoAlmacen no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _movimientoalmacenRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "MovimientoAlmacen no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
