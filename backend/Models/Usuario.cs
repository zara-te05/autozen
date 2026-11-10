namespace Autozen.Api.Models;

public class Usuario
{
    public int IdUsuario { get; set; } = default!;
    public int? TrabajadorId { get; set; }
    public string Nombre { get; set; } = default!;
    public string Rol { get; set; } = default!;
    public string Username {get; set;} = default!;
    public string Password {get; set;} = default!;
    public string? PuestoTrabajo { get; set; } = default!;
    public string? MetodoContacto { get; set; } = default!;

    /// <summary>Proyectos, Compras, Almacen o Evaluacion. Null para el Admin.</summary>
    public string? Area { get; set; }
}
