using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateMovimientoAlmacenDto
{
    public int AlmacenId { get; set; } = default!;
    public int? CompraId { get; set; } = default!;
    public int? SolicitudAlmacenId { get; set; } = default!;
    public string TipoMovimiento { get; set; } = default!;
    [Range(0.001, double.MaxValue, ErrorMessage = "Cantidad debe ser mayor a 0.")]
    public decimal Cantidad { get; set; } = default!;
    public DateTime FechaMovimiento { get; set; } = default!;
}
