namespace Autozen.Api.DTOs;

public class CreateValeSalidaDto
{
    public int OperacionId { get; set; } = default!;
    public int? UsuarioId { get; set; } = default!;
    public string EntregadoA { get; set; } = default!;
    public DateTime FechaEntrega { get; set; } = default!;
}
