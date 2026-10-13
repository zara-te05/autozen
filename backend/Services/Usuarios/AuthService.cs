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
            Expira = DateTime.UtcNow.AddMinutes(double.Parse(_config["Jwt:ExpiresInMinutes"] ?? "480"))
        };
    }

    /// <summary>
    /// Auto-registro público. Asigna estrictamente el rol base 'Usuario' sin privilegios administrativos.
    /// </summary>
    public async Task<RegisterUserResponseDto> RegisterAsync(RegisterUserRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Nombre) ||
            string.IsNullOrWhiteSpace(request.Username) ||
            string.IsNullOrWhiteSpace(request.Password) ||
            string.IsNullOrWhiteSpace(request.ConfirmarPassword))
        {
            throw new InvalidOperationException("Todos los campos obligatorios deben ser completados.");
        }

        if (request.Password.Length < 6)
        {
            throw new InvalidOperationException("La contraseña debe tener al menos 6 caracteres.");
        }

        if (request.Password != request.ConfirmarPassword)
        {
            throw new InvalidOperationException("Las contraseñas no coinciden.");
        }

        var existente = await _usuarioRepo.GetByUsername(request.Username.Trim());
        if (existente != null)
        {
            throw new InvalidOperationException($"El nombre de usuario '{request.Username}' ya está registrado.");
        }

        // Regla de Negocio: Auto-registro siempre recibe rol base 'Usuario'
        const string rolBase = "Usuario";
        string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

        var nuevoDto = new CreateUsuarioDto
        {
            Nombre = request.Nombre.Trim(),
            Username = request.Username.Trim(),
            Password = passwordHash,
            Rol = rolBase,
            TrabajadorId = null,
            PuestoTrabajo = null,
            MetodoContacto = request.MetodoContacto?.Trim()
        };

        var usuarioCreado = await _usuarioRepo.CreateAsync(nuevoDto);
        string? token = GenerarToken(usuarioCreado);

        return new RegisterUserResponseDto
        {
            IdUsuario = usuarioCreado.IdUsuario,
            Username = usuarioCreado.Username,
            Nombre = usuarioCreado.Nombre,
            Rol = usuarioCreado.Rol,
            Mensaje = "Usuario registrado exitosamente con rol base.",
            Token = token
        };
    }

    public string GenerarToken(Usuario usuario)
    {
        var jwtKey = _config["Jwt:Key"]
            ?? throw new InvalidOperationException("Jwt:Key no está configurada en appsettings.json.");

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, usuario.IdUsuario.ToString()),
            new Claim(JwtRegisteredClaimNames.UniqueName, usuario.Username),
            new Claim(ClaimTypes.Role, usuario.Rol),
            new Claim("nombre", usuario.Nombre ?? string.Empty),
            new Claim("puesto", usuario.PuestoTrabajo ?? string.Empty)
        };

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
