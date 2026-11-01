using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = Roles.Admin)] // Contiene salarios: solo Admin
public class TrabajadorController : ControllerBase
{
    private readonly ITrabajadorRepository _trabajadorRepository;

    public TrabajadorController(ITrabajadorRepository repository)
    {
        _trabajadorRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Trabajador>>> GetAll()
    {
        var items = await _trabajadorRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Trabajador>> GetById(int id)
    {
        var item = await _trabajadorRepository.GetByIdAsync(id);
        if (item is null)
        {
            return Problem(detail: "Trabajador no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<Trabajador>> Create([FromBody] CreateTrabajadorDto dto)
    {
        var created = await _trabajadorRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdTrabajador }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateTrabajadorDto dto)
    {
        var updated = await _trabajadorRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "Trabajador no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _trabajadorRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "Trabajador no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
