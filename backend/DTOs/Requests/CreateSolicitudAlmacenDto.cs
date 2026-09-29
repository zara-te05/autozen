namespace Autozen.Api.DTOs;

public class CreateSolicitudAlmacenDto
{
    public int AlmacenId { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public int? CantidadSolicitada { get; set; } = default!;
    public DateTime FechaSolicitud { get; set; } = default!;
}
