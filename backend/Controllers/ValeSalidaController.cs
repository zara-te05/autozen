using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = Lectura.Almacen)] // Leer: Admin, jefes y usuarios del área de Almacén. Escribir: Admin y jefe de Almacén
public class ValeSalidaController : ControllerBase
{
    private readonly IValeSalidaRepository _valesalidaRepository;

    public ValeSalidaController(IValeSalidaRepository repository)
    {
        _valesalidaRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ValeSalida>>> GetAll()
    {
        var items = await _valesalidaRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ValeSalida>> GetById(int id)
    {
        var item = await _valesalidaRepository.GetByIdAsync(id);
        if (item is null)
        {
            return Problem(detail: "ValeSalida no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<ActionResult<ValeSalida>> Create([FromBody] CreateValeSalidaDto dto)
    {
        var created = await _valesalidaRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdVale }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateValeSalidaDto dto)
    {
        var updated = await _valesalidaRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "ValeSalida no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _valesalidaRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "ValeSalida no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
