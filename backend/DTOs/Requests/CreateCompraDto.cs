using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateCompraDto
{
    public int SolicitudCompraId { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public string? NombrePiezas { get; set; } = default!;
    [Range(1, int.MaxValue, ErrorMessage = "CantidadPiezas debe ser mayor o igual a 1.")]
    public int? CantidadPiezas { get; set; } = default!;
    [Range(0, double.MaxValue, ErrorMessage = "CostoPiezas debe ser mayor o igual a 0.")]
    public decimal? CostoPiezas { get; set; } = default!;
}
