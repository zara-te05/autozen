namespace Autozen.Api.DTOs;

public class CreateFacturaDto
{
    public int OperacionId { get; set; } = default!;
    public DateTime FechaEmision { get; set; } = default!;
    public decimal? MontoTotal { get; set; } = default!;
    public string? EstadoPago { get; set; } = default!;
}
