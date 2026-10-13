using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Autenticación obligatoria
public class AlmacenController : ControllerBase
{
    private readonly AlmacenInventarioService _almacenService;

    public AlmacenController(AlmacenInventarioService almacenService)
    {
        _almacenService = almacenService;
    }

    /// <summary>
    /// Consulta el catálogo completo de piezas y materiales con su stock disponible y costos.
    /// </summary>
    [HttpGet("stock")]
    [HttpGet]
    public async Task<IActionResult> GetAllStock()
    {
        var stock = await _almacenService.GetAllStockAsync();
        return Ok(stock);
    }

    /// <summary>
    /// Obtiene los detalles de una pieza específica del almacén.
    /// </summary>
    [HttpGet("stock/{id}")]
    public async Task<IActionResult> GetStockById(int id)
    {
        var item = await _almacenService.GetStockByIdAsync(id);
        return item == null 
            ? NotFound(new { message = $"Pieza #{id} no encontrada en almacén." }) 
            : Ok(item);
    }

    /// <summary>
    /// Da de alta una nueva pieza o material en el catálogo de almacén.
    /// Exclusivo para personal de Almacén y Administración.
    /// </summary>
    [HttpPost("stock")]
    [Authorize(Roles = "Admin,Almacen_Admin")]
    public async Task<IActionResult> CrearPieza([FromBody] CrearPiezaAlmacenRequestDto dto)
    {
        try
        {
            var creada = await _almacenService.CrearPiezaAsync(dto);
            return CreatedAtAction(nameof(GetStockById), new { id = creada.IdAlmacen }, creada);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Registra la salida de material hacia un proyecto, descuenta inventario y calcula el importe a cobrar al cliente.
    /// Permitido para Almacén, Administración y Líderes de Proyecto.
    /// </summary>
    [HttpPost("salida")]
    [Authorize(Roles = "Admin,Almacen_Admin,Proyecto_Lider")]
    public async Task<IActionResult> RegistrarSalida([FromBody] RegistrarSalidaMaterialRequestDto dto)
    {
        try
        {
            var resultado = await _almacenService.RegistrarSalidaMaterialAsync(dto);
            return Ok(new
            {
                message = "Salida de material registrada exitosamente.",
                consumo = resultado
            });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Consulta la contabilidad de todos los materiales consumidos por un proyecto y el monto total a cobrar.
    /// </summary>
    [HttpGet("proyecto/{idProyecto}/consumo")]
    public async Task<IActionResult> GetConsumoPorProyecto(int idProyecto)
    {
        var consumos = await _almacenService.GetConsumoMaterialPorProyectoAsync(idProyecto);
        decimal granTotal = consumos.Sum(c => c.TotalACobrar);

        return Ok(new
        {
            idProyecto = idProyecto,
            totalCobroMateriales = granTotal,
            detalles = consumos
        });
    }
}
