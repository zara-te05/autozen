using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Leer: cualquier usuario autenticado. Escribir: Admin y jefe de Compras
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
            return Problem(detail: "SolicitudCompra no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Compras)]
    public async Task<ActionResult<SolicitudCompra>> Create([FromBody] CreateSolicitudCompraDto dto)
    {
        var created = await _solicitudcompraRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdSolicitudCompra }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Compras)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateSolicitudCompraDto dto)
    {
        var updated = await _solicitudcompraRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "SolicitudCompra no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Compras)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _solicitudcompraRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "SolicitudCompra no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
