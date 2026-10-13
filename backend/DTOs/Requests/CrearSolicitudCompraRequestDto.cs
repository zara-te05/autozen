namespace Autozen.Api.DTOs;

public class CrearSolicitudCompraRequestDto
{
    public int OperacionId { get; set; } // ID del proyecto
    public int? ProveedorId { get; set; }
    public string NombrePiezasCotizadas { get; set; } = string.Empty;
    public int CantidadPiezasCotizadas { get; set; }
}
