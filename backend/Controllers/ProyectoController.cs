using System.Security.Claims;
using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

/// <summary>Proyectos del taller (clientes y aseguradoras), sus etapas y fotos.</summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProyectoController : ControllerBase
{
    private readonly ProyectosTallerService _servicio;

    public ProyectoController(ProyectosTallerService servicio) => _servicio = servicio;

    /// <param name="tipo">Cliente o Aseguradora (opcional).</param>
    /// <param name="archivados">true: solo archivados; false: solo activos; sin valor: todos.</param>
    [HttpGet]
    public async Task<ActionResult<List<ProyectoTallerDto>>> Listar([FromQuery] string? tipo, [FromQuery] bool? archivados) =>
        Ok(await _servicio.ListarAsync(tipo, archivados));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ProyectoTallerDto>> Obtener(int id) => Ok(await _servicio.ObtenerAsync(id));

    /// <summary>Crea el proyecto con los datos de la Evaluación de Daños.</summary>
    [HttpPost]
    [Authorize(Roles = Edicion.CrearProyecto)]
    public async Task<ActionResult<ProyectoTallerDto>> Crear([FromBody] GuardarProyectoRequest request)
    {
        var creado = await _servicio.CrearAsync(request, UsuarioId());
        return CreatedAtAction(nameof(Obtener), new { id = creado.Id }, creado);
    }

    [HttpPut("{id:int}")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<ActionResult<ProyectoTallerDto>> Actualizar(int id, [FromBody] GuardarProyectoRequest request) =>
        Ok(await _servicio.ActualizarAsync(id, request));

    [HttpPost("{id:int}/avanzar")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<ActionResult<ProyectoTallerDto>> Avanzar(int id) => Ok(await _servicio.AvanzarEtapaAsync(id));

    [HttpPost("{id:int}/archivar")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<ActionResult<ProyectoTallerDto>> Archivar(int id) => Ok(await _servicio.CambiarArchivadoAsync(id, true));

    [HttpPost("{id:int}/restaurar")]
    [Authorize(Roles = Edicion.Proyectos)]
    public async Task<ActionResult<ProyectoTallerDto>> Restaurar(int id) => Ok(await _servicio.CambiarArchivadoAsync(id, false));

    [HttpGet("{id:int}/fotos/{idFoto:int}")]
    public async Task<IActionResult> Foto(int id, int idFoto)
    {
        var (ruta, tipoContenido) = await _servicio.ObtenerFotoAsync(id, idFoto);
        return PhysicalFile(ruta, tipoContenido);
    }

    /// <summary>Sube una foto (campo de formulario "archivo"). Máximo 10 MB.</summary>
    [HttpPost("{id:int}/fotos")]
    [Authorize(Roles = Edicion.CrearProyecto)]
    [RequestSizeLimit(11 * 1024 * 1024)]
    public async Task<ActionResult<FotoProyectoDto>> SubirFoto(int id, IFormFile archivo) => Ok(await _servicio.AgregarFotoAsync(id, archivo));

    [HttpDelete("{id:int}/fotos/{idFoto:int}")]
    [Authorize(Roles = Edicion.CrearProyecto)]
    public async Task<IActionResult> EliminarFoto(int id, int idFoto)
    {
        await _servicio.EliminarFotoAsync(id, idFoto);
        return NoContent();
    }

    [HttpGet("{id:int}/documentos/{idDocumento:int}")]
    public async Task<IActionResult> Documento(int id, int idDocumento)
    {
        var (ruta, nombre) = await _servicio.ObtenerDocumentoAsync(id, idDocumento);
        return PhysicalFile(ruta, "application/pdf", nombre);
    }

    /// <summary>Sube un PDF de la aseguradora (campo de formulario "archivo"). Máximo 20 MB.</summary>
    [HttpPost("{id:int}/documentos")]
    [Authorize(Roles = Edicion.CrearProyecto)]
    [RequestSizeLimit(21 * 1024 * 1024)]
    public async Task<ActionResult<DocumentoProyectoDto>> SubirDocumento(int id, IFormFile archivo) =>
        Ok(await _servicio.AgregarDocumentoAsync(id, archivo));

    [HttpDelete("{id:int}/documentos/{idDocumento:int}")]
    [Authorize(Roles = Edicion.CrearProyecto)]
    public async Task<IActionResult> EliminarDocumento(int id, int idDocumento)
    {
        await _servicio.EliminarDocumentoAsync(id, idDocumento);
        return NoContent();
    }

    private int? UsuarioId()
    {
        var valor = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        return int.TryParse(valor, out var id) ? id : null;
    }
}
