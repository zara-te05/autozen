namespace Autozen.Api.DTOs;

public class DevolverHerramientaRequestDto
{
    public string EstadoDevuelto { get; set; } = "Operativa"; // Estado físico al retornar
    public DateTime? FechaDevolucion { get; set; } // Fecha y hora de retorno
}
