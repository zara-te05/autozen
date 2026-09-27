using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsuarioController : ControllerBase
{
    private readonly IUsuarioRepository _usuarioRepository;

    public UsuarioController(IUsuarioRepository repository)
    {
        _usuarioRepository = repository;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Usuario>>> GetAll()
    {
        var items = await _usuarioRepository.GetAllAsync();
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Usuario>> GetById(int id)
    {
        var item = await _usuarioRepository.GetByIdAsync(id);
        if (item is null)
        {
            return NotFound(new { message = "Usuario no encontrado." });
        }
        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<Usuario>> Create([FromBody] CreateUsuarioDto dto)
    {
        var created = await _usuarioRepository.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.IdUsuario }, created);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateUsuarioDto dto)
    {
        var updated = await _usuarioRepository.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "Usuario no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        var deleted = await _usuarioRepository.DeleteAsync(id);
        if (!deleted)
        {
            return NotFound(new { message = "Usuario no encontrado para eliminar." });
        }
        return NoContent();
    }
}
