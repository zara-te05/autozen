using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateDetalleCotizacionDto
{
    public int CotizacionId { get; set; } = default!;
    public int? TrabajadorId { get; set; } = default!;
    public string? DescripcionTrabajoPieza { get; set; } = default!;
    [Range(0, double.MaxValue, ErrorMessage = "CostoPiezasTomadasAlmacen debe ser mayor o igual a 0.")]
    public decimal? CostoPiezasTomadasAlmacen { get; set; } = default!;
    [Range(1, int.MaxValue, ErrorMessage = "TrabajadoresAsignados debe ser mayor o igual a 1.")]
    public int? TrabajadoresAsignados { get; set; } = default!;
}
