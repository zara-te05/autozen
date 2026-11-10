using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = Lectura.Evaluacion)] // Leer: Admin, jefes y usuarios del área de Evaluación (y Proyectos). Escribir: según cada acción
public class ClienteController : ControllerBase
{
    private readonly IClienteRepository _clienteRepository;

    public ClienteController(IClienteRepository repository)
    {
        _clienteRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Cliente>>> GetAll()
    {
        var items = await _clienteRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Cliente>> GetById(int id)
    {
        var item = await _clienteRepository.GetByIdAsync(id);
        if (item is null)
        {
            return Problem(detail: "Cliente no encontrado.", statusCode: StatusCodes.Status404NotFound);
        }
        return Ok(item);
    }

    [HttpPost]
    [Authorize(Roles = Edicion.Evaluacion)]
    public async Task<ActionResult<Cliente>> Create([FromBody] CreateClienteDto dto)
    {
        var created = await _clienteRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdCliente }, created);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Edicion.Evaluacion)]
    public async Task<IActionResult> Update(int id, [FromBody] CreateClienteDto dto)
    {
        var updated = await _clienteRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return Problem(detail: "Cliente no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Edicion.Evaluacion)]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _clienteRepository.DeleteAsync(id);
        if (!deleted)
        {
            return Problem(detail: "Cliente no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
        }
        return NoContent();
    }
}
