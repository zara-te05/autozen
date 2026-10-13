namespace Autozen.Api.DTOs;

public class EditarProyectoRequestDto
{
    // Datos actualizables del Camión
    public string Placas { get; set; } = string.Empty;
    public string? Marca { get; set; }
    public string? Modelo { get; set; }
    public DateTime? TiempoEsperado { get; set; }
    public string? DanoEstimado { get; set; }

    // Datos actualizables de la Operación
    public int? UsuarioIdResponsable { get; set; }
    public DateTime? FechaEstimadaFinalizacion { get; set; }
    public string? EstadoOperacion { get; set; }
}
