namespace Autozen.Api.DTOs;

public class PrestarHerramientaRequestDto
{
    public int OperacionId { get; set; } // ID del proyecto
    public int? TrabajadorId { get; set; } // Mecánico o trabajador responsable
    public string NombreHerramienta { get; set; } = string.Empty;
    public string EstadoSalida { get; set; } = "Operativa"; // Estado físico al retirar
    public DateTime? FechaSalida { get; set; } // Fecha y hora de retiro
}
