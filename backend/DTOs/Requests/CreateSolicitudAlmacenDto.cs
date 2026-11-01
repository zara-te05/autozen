using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateSolicitudAlmacenDto
{
    public int AlmacenId { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    [Range(0.001, double.MaxValue, ErrorMessage = "CantidadSolicitada debe ser mayor a 0.")]
    public decimal? CantidadSolicitada { get; set; } = default!;
    public DateTime FechaSolicitud { get; set; } = default!;
}
