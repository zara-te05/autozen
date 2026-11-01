using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class DepartamentoController : ControllerBase
{
    private readonly DepartamentoService _servicio;

    public DepartamentoController(DepartamentoService servicio) => _servicio = servicio;

    [HttpGet]
    public async Task<ActionResult<List<DepartamentoDto>>> Listar() => Ok(await _servicio.ListarAsync());

    [HttpPost]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<DepartamentoDto>> Crear([FromBody] DepartamentoDto dto) => Ok(await _servicio.GuardarAsync(null, dto));

    [HttpPut("{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<DepartamentoDto>> Editar(int id, [FromBody] DepartamentoDto dto) => Ok(await _servicio.GuardarAsync(id, dto));

    [HttpDelete("{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Eliminar(int id)
    {
        await _servicio.EliminarAsync(id);
        return NoContent();
    }
}
