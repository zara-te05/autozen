namespace Autozen.Api.Models;

public class SolicitudAlmacen
{
    public int IdSolicitudAlmacen { get; set; } = default!;
    public int AlmacenId { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public int? CantidadSolicitada { get; set; } = default!;
    public DateTime FechaSolicitud { get; set; } = default!;
}
