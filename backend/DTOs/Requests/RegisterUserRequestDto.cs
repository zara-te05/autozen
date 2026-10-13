namespace Autozen.Api.DTOs;

public class RegisterUserRequestDto
{
    public string Nombre { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string ConfirmarPassword { get; set; } = string.Empty;
    public string? MetodoContacto { get; set; }
}
