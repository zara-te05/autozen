namespace Autozen.Api.DTOs;

public class EditarUsuarioAdminRequestDto
{
    public string Nombre { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Rol { get; set; } = "Usuario";
    public string? PuestoTrabajo { get; set; }
    public int? TrabajadorId { get; set; }
    public string? MetodoContacto { get; set; }
    public string? Password { get; set; } // Opcional: si viene vacío, conserva la contraseña actual
}
