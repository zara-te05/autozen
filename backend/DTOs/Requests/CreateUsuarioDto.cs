namespace Autozen.Api.DTOs;

public class CreateUsuarioDto
{
    public int? TrabajadorId { get; set; }
    public string Nombre { get; set; } = default!;
    public string Rol { get; set; } = default!;
    public string Username {get; set;} = default!;
    public string Password {get; set;} = default!;
    public string? PuestoTrabajo { get; set; } = default!;
    public string? MetodoContacto { get; set; } = default!;
}
