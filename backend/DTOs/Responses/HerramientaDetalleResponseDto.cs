namespace Autozen.Api.DTOs;

public class HerramientaDetalleResponseDto
{
    public int IdEquipo { get; set; }
    public int OperacionId { get; set; }
    public string? PlacasCamion { get; set; }
    public int? TrabajadorId { get; set; }
    public string? NombreTrabajador { get; set; }
    public string NombreHerramienta { get; set; } = string.Empty;
    public string EstadoSalida { get; set; } = string.Empty;
    public string? EstadoDevuelto { get; set; }
    public DateTime? FechaSalida { get; set; }
    public DateTime? FechaDevolucion { get; set; }
    public bool EstaDevuelta { get; set; }
}
