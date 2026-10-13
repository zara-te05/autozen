namespace Autozen.Api.DTOs;

public class CrearUsuarioAdminRequestDto
{
    public string Nombre { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Rol { get; set; } = "Usuario"; // Admin, Proyecto_Lider, Compras_Admin, Almacen_Admin, Usuario
    public string? PuestoTrabajo { get; set; }
    public int? TrabajadorId { get; set; }
    public string? MetodoContacto { get; set; }
}
