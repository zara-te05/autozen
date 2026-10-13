namespace Autozen.Api.DTOs;

public class EditarOrdenCompraRequestDto
{
    public string NombrePiezas { get; set; } = string.Empty;
    public int CantidadPiezas { get; set; }
    public decimal CostoPiezas { get; set; }
}
