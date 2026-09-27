namespace Autozen.Api.DTOs;

public class CreateEquipoAlmacenDto
{
    public int OperacionId { get; set; } = default!;
    public int? TrabajadorId { get; set; } = default!;
    public string NombreHerramienta { get; set; } = default!;
    public string? EstadoSalida { get; set; } = default!;
    public string? EstadoDevuelto { get; set; } = default!;
}
