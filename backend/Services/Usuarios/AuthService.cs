using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.IdentityModel.Tokens;

namespace Autozen.Api.Services;

public class AuthService
{
    private readonly IUsuarioRepository _usuarioRepo;
    private readonly IConfiguration _config;

    public AuthService(IUsuarioRepository usuarioRepo, IConfiguration config)
    {
        _usuarioRepo = usuarioRepo;
        _config = config;
    }

    /// <summary>
    /// Inicio de sesión para cualquier usuario registrado. Valida credenciales y emite JWT firmado con su rol.
    /// </summary>
    public async Task<LoginResponseDto?> LoginAsync(LoginRequestDTO request)
    {
        if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrWhiteSpace(request.Password))
            return null;

        var usuario = await _usuarioRepo.GetByUsername(request.Username.Trim());
        if (usuario == null)
            return null;

        bool passwordValid = BCrypt.Net.BCrypt.Verify(request.Password, usuario.Password);
        if (!passwordValid)
            return null;

        string tokenGenerado = GenerarToken(usuario);

        return new LoginResponseDto
        {
            Token = tokenGenerado,
            IdUsuario = usuario.IdUsuario,
            Username = usuario.Username,
            Rol = usuario.Rol,
            Nombre = usuario.Nombre,
            Area = Areas.DeRol(usuario.Rol) ?? usuario.Area,
            Expira = DateTime.UtcNow.AddMinutes(double.Parse(_config["Jwt:ExpiresInMinutes"] ?? "480"))
        };
    }

    public string GenerarToken(Usuario usuario)
    {
        var jwtKey = _config["Jwt:Key"]
            ?? throw new InvalidOperationException("Jwt:Key no está configurada en appsettings.json.");

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuario.IdUsuario.ToString()),
            new(JwtRegisteredClaimNames.UniqueName, usuario.Username),
            new(ClaimTypes.Role, usuario.Rol),
            new("nombre", usuario.Nombre ?? string.Empty),
            new("puesto", usuario.PuestoTrabajo ?? string.Empty)
        };
        // Área del usuario: limita qué departamentos puede leer un usuario con rol 'Usuario'
        var area = Areas.DeRol(usuario.Rol) ?? usuario.Area;
        if (!string.IsNullOrEmpty(area)) claims.Add(new Claim(Areas.Claim, area));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expira = DateTime.UtcNow.AddMinutes(double.Parse(_config["Jwt:ExpiresInMinutes"] ?? "480"));

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: expira,
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
