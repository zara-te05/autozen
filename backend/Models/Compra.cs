namespace Autozen.Api.Models;

public class Compra
{
    public int IdCompra { get; set; } = default!;
    public int SolicitudCompraId { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public string? NombrePiezas { get; set; } = default!;
    public int? CantidadPiezas { get; set; } = default!;
    public decimal? CostoPiezas { get; set; } = default!;
}
