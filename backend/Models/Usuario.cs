namespace Autozen.Api.Models;

public class Usuario
{
    public int IdUsuario { get; set; } = default!;
    public string Nombre { get; set; } = default!;
    public string Rol { get; set; } = default!;
    public string? PuestoTrabajo { get; set; } = default!;
    public string? MetodoContacto { get; set; } = default!;
}
