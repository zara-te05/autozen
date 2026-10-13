using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class RegisterController : ControllerBase
{
    private readonly RegisterUserService _registerUserService;

    public RegisterController(RegisterUserService registerUserService)
    {
        _registerUserService = registerUserService;
    }

    [HttpPost]
    public async Task<IActionResult> Register([FromBody] RegisterUserRequestDto request)
    {
        try
        {
            var resultado = await _registerUserService.RegistrarAsync(request);
            return Ok(resultado);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
