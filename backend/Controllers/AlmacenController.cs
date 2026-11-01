using System.Security.Claims;
using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

/// <summary>Catálogo del almacén, categorías y vales de salida de material.</summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AlmacenController : ControllerBase
{
    private readonly AlmacenService _servicio;

    public AlmacenController(AlmacenService servicio) => _servicio = servicio;

    // ---------- Artículos ----------

    [HttpGet("articulos")]
    public async Task<ActionResult<List<ArticuloDto>>> Articulos() => Ok(await _servicio.ListarArticulosAsync());

    [HttpPost("articulos")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<ActionResult<ArticuloDto>> CrearArticulo([FromBody] GuardarArticuloRequest request) =>
        Ok(await _servicio.GuardarArticuloAsync(null, request));

    [HttpPut("articulos/{id:int}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<ActionResult<ArticuloDto>> EditarArticulo(int id, [FromBody] GuardarArticuloRequest request) =>
        Ok(await _servicio.GuardarArticuloAsync(id, request));

    [HttpDelete("articulos/{id:int}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> EliminarArticulo(int id)
    {
        await _servicio.EliminarArticuloAsync(id);
        return NoContent();
    }

    // ---------- Categorías ----------

    [HttpGet("categorias")]
    public async Task<ActionResult<List<CategoriaAlmacenDto>>> Categorias() => Ok(await _servicio.ListarCategoriasAsync());

    [HttpPost("categorias")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<ActionResult<CategoriaAlmacenDto>> CrearCategoria([FromBody] GuardarCategoriaRequest request) =>
        Ok(await _servicio.GuardarCategoriaAsync(null, request));

    [HttpPut("categorias/{id:int}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<ActionResult<CategoriaAlmacenDto>> RenombrarCategoria(int id, [FromBody] GuardarCategoriaRequest request) =>
        Ok(await _servicio.GuardarCategoriaAsync(id, request));

    [HttpDelete("categorias/{id:int}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> EliminarCategoria(int id)
    {
        await _servicio.EliminarCategoriaAsync(id);
        return NoContent();
    }

    // ---------- Vales de material ----------

    [HttpGet("vales-material")]
    public async Task<ActionResult<List<ValeMaterialDto>>> ValesMaterial([FromQuery] int? proyectoId) =>
        Ok(await _servicio.ListarValesMaterialAsync(proyectoId));

    [HttpPost("vales-material")]
    [Authorize(Roles = Edicion.ValesAlmacen)]
    public async Task<ActionResult<ValeMaterialDto>> CrearValeMaterial([FromBody] CrearValeMaterialRequest request) =>
        Ok(await _servicio.CrearValeMaterialAsync(request));

    // ---------- Entrega de placas / resguardos ----------

    [HttpGet("resguardos")]
    public async Task<ActionResult<List<ResguardoDto>>> Resguardos() => Ok(await _servicio.ListarResguardosAsync());

    [HttpPost("resguardos")]
    [Authorize(Roles = Edicion.Almacen)]
    [RequestSizeLimit(1024 * 1024)]
    public async Task<ActionResult<ResguardoDto>> RegistrarResguardo([FromBody] ResguardoDto request)
    {
        var valor = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        return Ok(await _servicio.RegistrarResguardoAsync(request, int.TryParse(valor, out var id) ? id : null));
    }

    [HttpPost("resguardos/{id:int}/salida")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<ActionResult<ResguardoDto>> SalidaResguardo(int id, [FromBody] SalidaResguardoRequest request) =>
        Ok(await _servicio.RegistrarSalidaResguardoAsync(id, request));

    [HttpDelete("resguardos/{id:int}")]
    [Authorize(Roles = Edicion.Almacen)]
    public async Task<IActionResult> EliminarResguardo(int id)
    {
        await _servicio.EliminarResguardoAsync(id);
        return NoContent();
    }

    /// <summary>Cancela el vale: el material regresa al almacén.</summary>
    [HttpDelete("vales-material/{id:int}")]
    [Authorize(Roles = Edicion.ValesAlmacen)]
    public async Task<IActionResult> CancelarValeMaterial(int id)
    {
        await _servicio.CancelarValeMaterialAsync(id);
        return NoContent();
    }
}
