namespace Autozen.Api.Models;

public class Factura
{
    public int IdFactura { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public DateTime FechaEmision { get; set; } = default!;
    public decimal? MontoTotal { get; set; } = default!;
    public string? EstadoPago { get; set; } = default!;
}
