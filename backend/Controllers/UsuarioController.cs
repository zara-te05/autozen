using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsuarioController : ControllerBase
{
    private readonly UsuarioService _usuarioService;

    public UsuarioController(UsuarioService service)
    {
        _usuarioService = service;
    }

    [HttpGet]
    [Authorize(Roles ="Admin")]
    public async Task<IActionResult> GetAll() => Ok(await _usuarioService.GetAllAsync());

    [HttpGet("{id}")]
    public async Task<ActionResult<Usuario>> GetById(int id)
    {
        var item = await _usuarioService.GetByIdAsync(id);
        return item is null ? NotFound() : Ok(item);
    }

    [HttpPost]
    [Authorize(Roles ="Admin")]
    public async Task<ActionResult<Usuario>> Create([FromBody] CreateUsuarioDto dto)
    {
        try
        {
            var created = await _usuarioService.CrearUsuario(dto);
            return CreatedAtAction(nameof(GetById), new { id = created.IdUsuario }, created);
        }
        catch(InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message }); 
        }
    }

    [HttpPut("{id}")]
    [Authorize(Roles ="Admin")]
    public async Task<IActionResult> Update(int id, [FromBody] CreateUsuarioDto dto)
    {
        var updated = await _usuarioService.UpdateAsync(id, dto);
        if (!updated)
        {
            return NotFound(new { message = "Usuario no encontrado para actualizar." });
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    [Authorize(Roles ="Admin")]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            var deleted = await _usuarioService.EliminarAsync(id);
            if (!deleted)
                return NotFound(new { message = "Usuario no encontrado para eliminar." });
            
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message }); // "No se puede eliminar el admin"
        }
    }
}
