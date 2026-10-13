using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Autenticación obligatoria
public class HerramientasController : ControllerBase
{
    private readonly HerramientasService _herramientasService;

    public HerramientasController(HerramientasService herramientasService)
    {
        _herramientasService = herramientasService;
    }

    /// <summary>
    /// Consulta el historial completo de préstamos y devoluciones de herramientas en el taller.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var herramientas = await _herramientasService.GetAllHerramientasAsync();
        return Ok(herramientas);
    }

    /// <summary>
    /// Consulta las herramientas que están actualmente prestadas (en uso en el taller).
    /// </summary>
    [HttpGet("activas")]
    public async Task<IActionResult> GetHerramientasEnUso()
    {
        var activas = await _herramientasService.GetHerramientasEnUsoAsync();
        return Ok(activas);
    }

    /// <summary>
    /// Consulta las herramientas asociadas a un proyecto en específico.
    /// </summary>
    [HttpGet("proyecto/{idProyecto}")]
    public async Task<IActionResult> GetByProyecto(int idProyecto)
    {
        var herramientas = await _herramientasService.GetHerramientasPorProyectoAsync(idProyecto);
        return Ok(herramientas);
    }

    /// <summary>
    /// Registra la salida y préstamo de una herramienta para su uso en un proyecto.
    /// Permitido para Almacén, Administración y Líderes de Proyecto.
    /// </summary>
    [HttpPost("prestar")]
    [Authorize(Roles = "Admin,Almacen_Admin,Proyecto_Lider")]
    public async Task<IActionResult> Prestar([FromBody] PrestarHerramientaRequestDto dto)
    {
        try
        {
            var prestamo = await _herramientasService.PrestarHerramientaAsync(dto);
            return Ok(new
            {
                message = "Préstamo de herramienta registrado exitosamente.",
                herramienta = prestamo
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Registra la devolución de una herramienta prestada evaluando su estado de retorno.
    /// Permitido para Almacén, Administración y Líderes de Proyecto.
    /// </summary>
    [HttpPost("{id}/devolver")]
    [Authorize(Roles = "Admin,Almacen_Admin,Proyecto_Lider")]
    public async Task<IActionResult> Devolver(int id, [FromBody] DevolverHerramientaRequestDto dto)
    {
        var actualizado = await _herramientasService.DevolverHerramientaAsync(id, dto);
        if (!actualizado)
        {
            return NotFound(new { message = $"Registro de herramienta #{id} no encontrado." });
        }

        return Ok(new { message = "Devolución de herramienta registrada correctamente." });
    }
}
