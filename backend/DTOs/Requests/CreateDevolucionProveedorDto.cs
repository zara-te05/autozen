using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateDevolucionProveedorDto
{
    public int CompraId { get; set; } = default!;
    public int ProveedorId { get; set; } = default!;
    public string Motivo { get; set; } = default!;
    public DateTime FechaDevolucion { get; set; } = default!;
    public string? EstadoDevolucion { get; set; } = default!;
    [Range(0, double.MaxValue, ErrorMessage = "MontoReembolso debe ser mayor o igual a 0.")]
    public decimal? MontoReembolso { get; set; } = default!;
}
