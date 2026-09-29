namespace Autozen.Api.DTOs;

public class CreateMovimientoAlmacenDto
{
    public int AlmacenId { get; set; } = default!;
    public int? CompraId { get; set; } = default!;
    public int? SolicitudAlmacenId { get; set; } = default!;
    public string TipoMovimiento { get; set; } = default!;
    public int Cantidad { get; set; } = default!;
    public DateTime FechaMovimiento { get; set; } = default!;
}
