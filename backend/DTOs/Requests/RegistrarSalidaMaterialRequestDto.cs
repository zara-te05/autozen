namespace Autozen.Api.DTOs;

public class RegistrarSalidaMaterialRequestDto
{
    public int OperacionId { get; set; } // ID del proyecto
    public int AlmacenId { get; set; }   // ID de la pieza o material en almacén
    public int Cantidad { get; set; }    // Cantidad a descontar y cargar al proyecto
}
