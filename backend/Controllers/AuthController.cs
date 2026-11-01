using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace Autozen.Api.Controllers;

[AllowAnonymous]
[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly AuthService _authService;

    public AuthController(AuthService authService)
    {
        _authService = authService;
    }

    [EnableRateLimiting(Politicas.Login)]
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequestDTO request)
    {
        var resultado = await _authService.LoginAsync(request);
        if (resultado == null)
        {
            return Problem(detail: "Credenciales inválidas.", statusCode: StatusCodes.Status401Unauthorized);
        }

        return Ok(resultado);
    }
}
