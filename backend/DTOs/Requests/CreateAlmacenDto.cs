using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateAlmacenDto
{
    public string NombrePieza { get; set; } = default!;
    [Range(0, double.MaxValue, ErrorMessage = "CantidadStock debe ser mayor o igual a 0.")]
    public decimal? CantidadStock { get; set; } = default!;
    [Range(0, double.MaxValue, ErrorMessage = "CostoPiezas debe ser mayor o igual a 0.")]
    public decimal? CostoPiezas { get; set; } = default!;
}
