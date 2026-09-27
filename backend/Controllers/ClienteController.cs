using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
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
            return NotFound(new { message = "Cliente no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<Cliente>> Create([FromBody] CreateClienteDto dto)
    {
        var created = await _clienteRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdCliente }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateClienteDto dto)
    {
        var updated = await _clienteRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "Cliente no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _clienteRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "Cliente no encontrado para eliminar." });
        }
        return NoContent();
    }
}
