namespace Autozen.Api.Models;

public class SolicitudCompra
{
    public int IdSolicitudCompra { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public int? UsuarioId { get; set; } = default!;
    public int? ProveedorId { get; set; } = default!;
    public string? NombrePiezasCotizadas { get; set; } = default!;
    public int? CantidadPiezasCotizadas { get; set; } = default!;
    public DateTime FechaSolicitud { get; set; } = default!;
}
