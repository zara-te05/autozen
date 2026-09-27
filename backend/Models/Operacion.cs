namespace Autozen.Api.Models;

public class Operacion
{
    public int IdOperacion { get; set; } = default!;
    public int CamionId { get; set; } = default!;
    public int? UsuarioId { get; set; } = default!;
    public DateTime FechaInicio { get; set; } = default!;
    public DateTime FechaEstimadaFinalizacion { get; set; } = default!;
    public string? EstadoOperacion { get; set; } = default!;
}
