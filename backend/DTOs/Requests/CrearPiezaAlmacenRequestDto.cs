namespace Autozen.Api.DTOs;

public class CrearPiezaAlmacenRequestDto
{
    public string NombrePieza { get; set; } = string.Empty;
    public int CantidadStock { get; set; }
    public decimal CostoPiezas { get; set; }
}
