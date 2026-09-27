namespace Autozen.Api.Models;

public class DevolucionProveedor
{
    public int IdDevolucion { get; set; } = default!;
    public int CompraId { get; set; } = default!;
    public int ProveedorId { get; set; } = default!;
    public string Motivo { get; set; } = default!;
    public DateTime FechaDevolucion { get; set; } = default!;
    public string? EstadoDevolucion { get; set; } = default!;
    public decimal? MontoReembolso { get; set; } = default!;
}
