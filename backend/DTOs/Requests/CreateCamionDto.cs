namespace Autozen.Api.DTOs;

public class CreateCamionDto
{
    public int ClienteId { get; set; } = default!;
    public string Placas { get; set; } = default!;
    public string? Marca { get; set; } = default!;
    public string? Modelo { get; set; } = default!;
    public DateTime FechaEntrada { get; set; } = default!;
    public DateTime TiempoEsperado { get; set; } = default!;
}
