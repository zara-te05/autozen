using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = Lectura.Almacen)] // Leer: Admin, jefes y usuarios del área de Almacén. Escribir: según cada acción
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
            return Problem(detail: "SolicitudAlmacen no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<ActionResult<SolicitudAlmacen>> Create([FromBody] CreateSolicitudAlmacenDto dto)
    {
        var created = await _solicitudalmacenRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdSolicitudAlmacen }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateSolicitudAlmacenDto dto)
    {
        var updated = await _solicitudalmacenRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "SolicitudAlmacen no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _solicitudalmacenRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "SolicitudAlmacen no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
