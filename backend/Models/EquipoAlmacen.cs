namespace Autozen.Api.Models;

public class EquipoAlmacen
{
    public int IdEquipo { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public int? TrabajadorId { get; set; } = default!;
    public string NombreHerramienta { get; set; } = default!;
    public string? EstadoSalida { get; set; } = default!;
    public string? EstadoDevuelto { get; set; } = default!;
}
