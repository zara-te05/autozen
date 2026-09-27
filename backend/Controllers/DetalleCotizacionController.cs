using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class DetalleCotizacionController : ControllerBase
{
    private readonly IDetalleCotizacionRepository _detallecotizacionRepository;

    public DetalleCotizacionController(IDetalleCotizacionRepository repository)
    {
        _detallecotizacionRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<DetalleCotizacion>>> GetAll()
    {
        var items = await _detallecotizacionRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<DetalleCotizacion>> GetById(int id)
    {
        var item = await _detallecotizacionRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "DetalleCotizacion no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<DetalleCotizacion>> Create([FromBody] CreateDetalleCotizacionDto dto)
    {
        var created = await _detallecotizacionRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdDetalleCotizacion }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateDetalleCotizacionDto dto)
    {
        var updated = await _detallecotizacionRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "DetalleCotizacion no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _detallecotizacionRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "DetalleCotizacion no encontrado para eliminar." });
        }
        return NoContent();
    }
}
