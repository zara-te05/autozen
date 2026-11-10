namespace Autozen.Api.DTOs;

public class ActualizarPrivilegiosRequestDto
{
    public string Rol { get; set; } = string.Empty; // Admin, Proyecto_Lider, Compras_Admin, Almacen_Admin, Usuario
    public string? PuestoTrabajo { get; set; }
    public int? TrabajadorId { get; set; }
    public string? Area { get; set; }
}
