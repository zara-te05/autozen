namespace Autozen.Api.DTOs;

public class LoginResponseDto
{
    public string Token { get; set; } = string.Empty;
    public int IdUsuario { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string? Nombre { get; set; }
    public DateTime Expira { get; set; }
}
