using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsuarioController : ControllerBase
{
    private readonly UsuarioAdminService _usuarioAdminService;

    public UsuarioController(UsuarioAdminService usuarioAdminService)
    {
        _usuarioAdminService = usuarioAdminService;
    }

    [HttpGet]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> GetAll()
    {
        var usuarios = await _usuarioAdminService.GetAllAsync();
        return Ok(usuarios);
    }

    [HttpGet("{id}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> GetById(int id)
    {
        var item = await _usuarioAdminService.GetByIdAsync(id);
        return item is null ? Problem(detail: "Usuario no encontrado.", statusCode: StatusCodes.Status404NotFound) : Ok(item);
    }

    /// <summary>
    /// Alta de usuarios: Admin (cualquier rol) o jefe de departamento (solo rol 'Usuario').
    /// </summary>
    [HttpPost]
    [Authorize(Policy = Politicas.AltaUsuarios)]
    public async Task<IActionResult> Create([FromBody] CrearUsuarioAdminRequestDto dto)
    {
        try
        {
            var created = await _usuarioAdminService.CrearUsuarioConPrivilegiosAsync(dto, User.IsInRole(Roles.Admin));
            return CreatedAtAction(nameof(GetById), new { id = created.IdUsuario }, created);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status403Forbidden);
        }
        catch (InvalidOperationException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    [HttpPut("{id}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Update(int id, [FromBody] EditarUsuarioAdminRequestDto dto)
    {
        try
        {
            var updated = await _usuarioAdminService.EditarUsuarioAsync(id, dto);
            if (!updated)
            {
                return Problem(detail: "Usuario no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound);
            }
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    [HttpPatch("{id}/privilegios")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> ActualizarPrivilegios(int id, [FromBody] ActualizarPrivilegiosRequestDto dto)
    {
        try
        {
            var updated = await _usuarioAdminService.ActualizarPrivilegiosAsync(id, dto);
            if (!updated)
            {
                return Problem(detail: "Usuario no encontrado para asignar privilegios.", statusCode: StatusCodes.Status404NotFound);
            }
            return Ok(new { message = "Privilegios actualizados correctamente." });
        }
        catch (InvalidOperationException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            var deleted = await _usuarioAdminService.EliminarUsuarioAsync(id);
            if (!deleted)
            {
                return Problem(detail: "Usuario no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound);
            }
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status400BadRequest);
        }
    }
}
