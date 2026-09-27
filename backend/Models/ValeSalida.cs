namespace Autozen.Api.Models;

public class ValeSalida
{
    public int IdVale { get; set; } = default!;
    public int OperacionId { get; set; } = default!;
    public int? UsuarioId { get; set; } = default!;
    public string EntregadoA { get; set; } = default!;
    public DateTime FechaEntrega { get; set; } = default!;
}
