using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;
using Microsoft.IdentityModel.Tokens;

namespace Autozen.Api.Services;

public class RegisterUserService
{
    private readonly IUsuarioRepository _usuarioRepo;
    private readonly IConfiguration _config;

    public RegisterUserService(IUsuarioRepository usuarioRepo, IConfiguration config)
    {
        _usuarioRepo = usuarioRepo;
        _config = config;
    }

    public async Task<RegisterUserResponseDto> RegistrarAsync(RegisterUserRequestDto request)
    {
        // 1. Validar campos obligatorios
        if (string.IsNullOrWhiteSpace(request.Nombre) ||
            string.IsNullOrWhiteSpace(request.Username) ||
            string.IsNullOrWhiteSpace(request.Password) ||
            string.IsNullOrWhiteSpace(request.ConfirmarPassword))
        {
            throw new InvalidOperationException("Todos los campos obligatorios deben ser completados.");
        }

        // 2. Validar longitud mínima de contraseña
        if (request.Password.Length < 6)
        {
            throw new InvalidOperationException("La contraseña debe contener al menos 6 caracteres.");
        }

        // 3. Validar coincidencia de contraseñas
        if (request.Password != request.ConfirmarPassword)
        {
            throw new InvalidOperationException("Las contraseñas no coinciden.");
        }

        // 4. Validar que el nombre de usuario no esté registrado previamente
        var usuarioExistente = await _usuarioRepo.GetByUsername(request.Username.Trim());
        if (usuarioExistente != null)
        {
            throw new InvalidOperationException($"El nombre de usuario '{request.Username}' ya está en uso.");
        }

        // 5. Regla de Negocio: Rol base por defecto
        // En auto-registro NO se otorgan privilegios administrativos ni de área.
        // Se asigna el rol base 'Usuario'. Más adelante, un administrador podrá
        // vincularlo a un Trabajador específico o concederle permisos por área.
        const string rolPorDefecto = "Usuario";

        // 6. Hashear contraseña con BCrypt
        string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

        // 7. Preparar DTO interno para el repositorio
        var createDto = new CreateUsuarioDto
        {
            Nombre = request.Nombre.Trim(),
            Username = request.Username.Trim(),
            Password = passwordHash,
            Rol = rolPorDefecto,
            TrabajadorId = null, // Sin trabajador vinculado aún
            PuestoTrabajo = null, // Sin puesto asignado aún
            MetodoContacto = request.MetodoContacto?.Trim()
        };

        // 8. Guardar en PostgreSQL
        var usuarioCreado = await _usuarioRepo.CreateAsync(createDto);

        // 9. Generar Token JWT opcional para inicio de sesión inmediato
        string? tokenGenerado = GenerarToken(usuarioCreado);

        // 10. Retornar DTO de respuesta seguro
        return new RegisterUserResponseDto
        {
            IdUsuario = usuarioCreado.IdUsuario,
            Username = usuarioCreado.Username,
            Nombre = usuarioCreado.Nombre,
            Rol = usuarioCreado.Rol,
            Mensaje = "Usuario registrado exitosamente con rol base.",
            Token = tokenGenerado
        };
    }

    private string? GenerarToken(Usuario usuario)
    {
        var jwtKey = _config["Jwt:Key"];
        if (string.IsNullOrWhiteSpace(jwtKey))
            return null;

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, usuario.IdUsuario.ToString()),
            new Claim(JwtRegisteredClaimNames.UniqueName, usuario.Username),
            new Claim(ClaimTypes.Role, usuario.Rol),
            new Claim("nombre", usuario.Nombre ?? string.Empty),
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expira = DateTime.UtcNow.AddMinutes(
            double.Parse(_config["Jwt:ExpiresInMinutes"] ?? "480"));

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
