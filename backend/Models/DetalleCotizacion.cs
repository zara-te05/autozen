namespace Autozen.Api.Models;

public class DetalleCotizacion
{
    public int IdDetalleCotizacion { get; set; } = default!;
    public int CotizacionId { get; set; } = default!;
    public int? TrabajadorId { get; set; } = default!;
    public string? DescripcionTrabajoPieza { get; set; } = default!;
    public decimal? CostoPiezasTomadasAlmacen { get; set; } = default!;
    public int? TrabajadoresAsignados { get; set; } = default!;
}
