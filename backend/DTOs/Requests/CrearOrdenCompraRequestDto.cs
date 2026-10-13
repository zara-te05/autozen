namespace Autozen.Api.DTOs;

public class CrearOrdenCompraRequestDto
{
    public int SolicitudCompraId { get; set; }
    public int OperacionId { get; set; }
    public string NombrePiezas { get; set; } = string.Empty;
    public int CantidadPiezas { get; set; }
    public decimal CostoPiezas { get; set; }
}
