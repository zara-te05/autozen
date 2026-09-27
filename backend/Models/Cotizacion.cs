namespace Autozen.Api.Models;

public class Cotizacion
{
    public int IdCotizacion { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public int? TrabajadorId { get; set; } = default!;
    public decimal? ManoObraEstimada { get; set; } = default!;
    public decimal? CostoEstimadoPiezas { get; set; } = default!;
    public decimal? Total { get; set; } = default!;
    public string? EstadoCotizacion { get; set; } = default!;
}
