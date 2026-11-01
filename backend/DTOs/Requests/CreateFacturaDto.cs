using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateFacturaDto
{
    public int OperacionId { get; set; } = default!;
    public DateTime FechaEmision { get; set; } = default!;
    [Range(0, double.MaxValue, ErrorMessage = "MontoTotal debe ser mayor o igual a 0.")]
    public decimal? MontoTotal { get; set; } = default!;
    public string? EstadoPago { get; set; } = default!;
}
