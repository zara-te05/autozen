namespace Autozen.Api.DTOs;

public class CreateDevolucionProveedorDto
{
    public int CompraId { get; set; } = default!;
    public int ProveedorId { get; set; } = default!;
    public string Motivo { get; set; } = default!;
    public DateTime FechaDevolucion { get; set; } = default!;
    public string? EstadoDevolucion { get; set; } = default!;
    public decimal? MontoReembolso { get; set; } = default!;
}
