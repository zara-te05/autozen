using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin")]
public class UsuarioController : ControllerBase
{
    private readonly UsuarioAdminService _usuarioAdminService;

    public UsuarioController(UsuarioAdminService usuarioAdminService)
    {
        _usuarioAdminService = usuarioAdminService;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var usuarios = await _usuarioAdminService.GetAllAsync();
        return Ok(usuarios);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var item = await _usuarioAdminService.GetByIdAsync(id);
        return item is null ? NotFound(new { message = "Usuario no encontrado." }) : Ok(item);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CrearUsuarioAdminRequestDto dto)
    {
        try
        {
            var created = await _usuarioAdminService.CrearUsuarioConPrivilegiosAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = created.IdUsuario }, created);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] EditarUsuarioAdminRequestDto dto)
    {
        try
        {
            var updated = await _usuarioAdminService.EditarUsuarioAsync(id, dto);
            if (!updated)
            {
                return NotFound(new { message = "Usuario no encontrado para actualizar." });
            }
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("{id}/privilegios")]
    public async Task<IActionResult> ActualizarPrivilegios(int id, [FromBody] ActualizarPrivilegiosRequestDto dto)
    {
        try
        {
            var updated = await _usuarioAdminService.ActualizarPrivilegiosAsync(id, dto);
            if (!updated)
            {
                return NotFound(new { message = "Usuario no encontrado para asignar privilegios." });
            }
            return Ok(new { message = "Privilegios actualizados correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            var deleted = await _usuarioAdminService.EliminarUsuarioAsync(id);
            if (!deleted)
            {
                return NotFound(new { message = "Usuario no encontrado para eliminar." });
            }
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
