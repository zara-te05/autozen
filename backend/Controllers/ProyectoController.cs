using System.Security.Claims;
using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Todos los endpoints requieren autenticación
public class ProyectoController : ControllerBase
{
    private readonly ProyectoService _proyectoService;

    public ProyectoController(ProyectoService proyectoService)
    {
        _proyectoService = proyectoService;
    }

    /// <summary>
    /// Lista todos los proyectos con su camión, cliente y estado de avance.
    /// Accesible por cualquier usuario autenticado (lectura general).
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var proyectos = await _proyectoService.GetAllAsync();
        return Ok(proyectos);
    }

    /// <summary>
    /// Obtiene la ficha técnica completa de un proyecto por ID.
    /// </summary>
    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var proyecto = await _proyectoService.GetByIdAsync(id);
        return proyecto == null 
            ? NotFound(new { message = $"El proyecto con ID {id} no existe." }) 
            : Ok(proyecto);
    }

    /// <summary>
    /// Crea un nuevo proyecto (Camión + Cliente + Operación).
    /// Solo permitido para Administradores o Líderes de Proyecto.
    /// </summary>
    [HttpPost]
    [Authorize(Roles = "Admin,Proyecto_Lider")]
    public async Task<IActionResult> Create([FromBody] CrearProyectoRequestDto dto)
    {
        try
        {
            var creado = await _proyectoService.CrearProyectoAsync(dto);
            return CreatedAtAction(nameof(GetById), new { id = creado.IdProyecto }, creado);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Edita información del camión o avance del proyecto.
    /// Solo permitido para Administradores o Líderes de Proyecto.
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Roles = "Admin,Proyecto_Lider")]
    public async Task<IActionResult> Update(int id, [FromBody] EditarProyectoRequestDto dto)
    {
        try
        {
            var actualizado = await _proyectoService.EditarProyectoAsync(id, dto);
            if (!actualizado)
            {
                return NotFound(new { message = "Proyecto no encontrado para actualizar." });
            }
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Registra la solicitud de baja/eliminación de un proyecto justificando el motivo.
    /// Cualquier usuario del taller puede solicitar la baja si no tiene privilegios directos de borrado.
    /// </summary>
    [HttpPost("{id}/solicitar-baja")]
    public async Task<IActionResult> SolicitarBaja(int id, [FromBody] SolicitarBajaProyectoRequestDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Motivo))
        {
            return BadRequest(new { message = "Debe proporcionar el motivo de la solicitud de baja." });
        }

        string username = User.FindFirst(ClaimTypes.Name)?.Value 
            ?? User.Identity?.Name 
            ?? "Usuario";

        var solicitado = await _proyectoService.SolicitarBajaAsync(id, dto, username);
        if (!solicitado)
        {
            return NotFound(new { message = "Proyecto no encontrado para solicitar su baja." });
        }

        return Ok(new { message = "Solicitud de baja registrada exitosamente para revisión administrativa." });
    }

    /// <summary>
    /// Elimina o da de baja definitiva a un proyecto.
    /// Requiere privilegios en su área (Admin o Proyecto_Lider).
    /// </summary>
    [HttpDelete("{id}")]
    [Authorize(Roles = "Admin,Proyecto_Lider")]
    public async Task<IActionResult> Delete(int id)
    {
        var eliminado = await _proyectoService.EliminarProyectoAsync(id);
        if (!eliminado)
        {
            return NotFound(new { message = "Proyecto no encontrado para eliminar." });
        }

        return NoContent();
    }
}
