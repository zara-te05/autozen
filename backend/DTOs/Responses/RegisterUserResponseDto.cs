namespace Autozen.Api.DTOs;

public class RegisterUserResponseDto
{
    public int IdUsuario { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string Mensaje { get; set; } = string.Empty;
    public string? Token { get; set; }
}
