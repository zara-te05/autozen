using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CotizacionController : ControllerBase
{
    private readonly ICotizacionRepository _cotizacionRepository;

    public CotizacionController(ICotizacionRepository repository)
    {
        _cotizacionRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Cotizacion>>> GetAll()
    {
        var items = await _cotizacionRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Cotizacion>> GetById(int id)
    {
        var item = await _cotizacionRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "Cotizacion no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<Cotizacion>> Create([FromBody] CreateCotizacionDto dto)
    {
        var created = await _cotizacionRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdCotizacion }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateCotizacionDto dto)
    {
        var updated = await _cotizacionRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "Cotizacion no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _cotizacionRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "Cotizacion no encontrado para eliminar." });
        }
        return NoContent();
    }
}
