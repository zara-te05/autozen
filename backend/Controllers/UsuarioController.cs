using System.Security.Claims;
using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

/// <summary>
/// Usuarios del sistema.
/// - Admin: CRUD de todos los usuarios y roles.
/// - Jefes de departamento: CRUD solo de usuarios con rol 'Usuario' de su área (el servicio lo valida).
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = Politicas.AltaUsuarios)]
public class UsuarioController : ControllerBase
{
    private readonly UsuarioAdminService _usuarioAdminService;

    public UsuarioController(UsuarioAdminService usuarioAdminService)
    {
        _usuarioAdminService = usuarioAdminService;
    }

    private Solicitante Solicitante => new(User.FindFirstValue(ClaimTypes.Role) ?? Roles.Usuario, User.FindFirstValue(Areas.Claim));

    [HttpGet]
    public async Task<IActionResult> GetAll() => Ok(await _usuarioAdminService.GetAllAsync(Solicitante));

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var item = await _usuarioAdminService.GetByIdAsync(id, Solicitante);
        return item is null ? Problem(detail: "Usuario no encontrado.", statusCode: StatusCodes.Status404NotFound) : Ok(item);
    }

    /// <summary>Alta de usuarios: Admin (cualquier rol) o jefe de departamento (solo rol 'Usuario' de su área).</summary>
    [HttpPost]
    public Task<IActionResult> Create([FromBody] CrearUsuarioAdminRequestDto dto) => Ejecutar(async () =>
    {
        var created = await _usuarioAdminService.CrearUsuarioConPrivilegiosAsync(dto, Solicitante);
        return CreatedAtAction(nameof(GetById), new { id = created.IdUsuario }, created);
    });

    [HttpPut("{id}")]
    public Task<IActionResult> Update(int id, [FromBody] EditarUsuarioAdminRequestDto dto) => Ejecutar(async () =>
        await _usuarioAdminService.EditarUsuarioAsync(id, dto, Solicitante)
            ? NoContent()
            : Problem(detail: "Usuario no encontrado para actualizar.", statusCode: StatusCodes.Status404NotFound));

    [HttpPatch("{id}/privilegios")]
    [Authorize(Roles = Roles.Admin)]
    public Task<IActionResult> ActualizarPrivilegios(int id, [FromBody] ActualizarPrivilegiosRequestDto dto) => Ejecutar(async () =>
        await _usuarioAdminService.ActualizarPrivilegiosAsync(id, dto, Solicitante)
            ? Ok(new { message = "Privilegios actualizados correctamente." })
            : Problem(detail: "Usuario no encontrado para asignar privilegios.", statusCode: StatusCodes.Status404NotFound));

    [HttpDelete("{id}")]
    public Task<IActionResult> Delete(int id) => Ejecutar(async () =>
        await _usuarioAdminService.EliminarUsuarioAsync(id, Solicitante)
            ? NoContent()
            : Problem(detail: "Usuario no encontrado para eliminar.", statusCode: StatusCodes.Status404NotFound));

    private async Task<IActionResult> Ejecutar(Func<Task<IActionResult>> accion)
    {
        try
        {
            return await accion();
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
}
