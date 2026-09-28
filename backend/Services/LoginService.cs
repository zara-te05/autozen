using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Autozen.Api.DTOs;
using Autozen.Api.Repositories;
using Microsoft.IdentityModel.Tokens;

namespace Autozen.Api.Services
{
    public class LoginService
    {
        private readonly IUsuarioRepository _usuarioRepo;
        private readonly IConfiguration _config;

        public LoginService(IUsuarioRepository usuarioRepo, IConfiguration config)
        {
            _usuarioRepo = usuarioRepo;
            _config = config;
        }

        public async Task<LoginResponseDto?> AutenticarAsync(LoginRequestDTO request)
        {
            // Buscar usuario en la BD
            var usuario = await _usuarioRepo.GetByUsername(request.Username);

            if (usuario == null)
                return null; // No existe

            // VerificaMOS contraseña con BCrypt
            bool passwordValid = BCrypt.Net.BCrypt.Verify(request.Password, usuario.Password);

            if (!passwordValid)
                return null; // Contraseña incorrecta

            // CreaMOS los Claims (datos que viven dentro del token)
            var claims = new[]
            {
                new Claim(JwtRegisteredClaimNames.Sub, usuario.IdUsuario.ToString()),
                new Claim(JwtRegisteredClaimNames.UniqueName, usuario.Username),
                new Claim(ClaimTypes.Role, usuario.Rol),          // <-- El rol va aquí
                new Claim("nombre", usuario.Nombre ?? string.Empty),
            };

            // FirmaMOS el token con la clave secreta del appsettings.json
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
                _config["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key no configurada.")));

            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

            var expira = DateTime.UtcNow.AddMinutes(
                double.Parse(_config["Jwt:ExpiresInMinutes"] ?? "480"));

            var token = new JwtSecurityToken(
                issuer:   _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims:   claims,
                expires:  expira,
                signingCredentials: creds
            );

            // Devolver el token serializado + datos básicos del usuario
            return new LoginResponseDto
            {
                Token    = new JwtSecurityTokenHandler().WriteToken(token),
                IdUsuario = usuario.IdUsuario,
                Username  = usuario.Username,
                Rol       = usuario.Rol,
                Nombre    = usuario.Nombre,
                Expira    = expira,
            };
        }
    }
}
