namespace Autozen.Api.DTOs;

public class CreateCompraDto
{
    public int SolicitudCompraId { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public string? NombrePiezas { get; set; } = default!;
    public int? CantidadPiezas { get; set; } = default!;
    public decimal? CostoPiezas { get; set; } = default!;
}
