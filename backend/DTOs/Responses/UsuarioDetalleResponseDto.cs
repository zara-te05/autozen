namespace Autozen.Api.DTOs;

public class UsuarioDetalleResponseDto
{
    public int IdUsuario { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public string? PuestoTrabajo { get; set; }
    public int? TrabajadorId { get; set; }
    public string? MetodoContacto { get; set; }
}
