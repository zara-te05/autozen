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

    /// <summary>Área del usuario (Proyectos, Compras, Almacen, Evaluacion). Obligatoria para el rol 'Usuario' cuando lo crea el Admin; si lo crea un jefe, se usa el área del jefe.</summary>
    public string? Area { get; set; }
}
