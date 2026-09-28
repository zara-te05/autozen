using Autozen.Api.DTOs;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Mvc;

namespace Autozen.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LoginController : ControllerBase
    {
        private readonly LoginService _loginService;

        public LoginController(LoginService loginService)
        {
            _loginService = loginService;
        }

        [HttpPost]
        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequestDTO request)
        {
            var resultado = await _loginService.AutenticarAsync(request);

            if (resultado == null)
                return Unauthorized(new { message = "Credenciales invalidas." });

            return Ok(resultado); // Devuelve el token JWT + datos del usuario
        }
    }   
}