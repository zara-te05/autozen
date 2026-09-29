namespace Autozen.Api.DTOs;

public class CreateProveedorDto
{
    public string NombreProveedor { get; set; } = default!;
    public string? Contacto { get; set; } = default!;
    public int? TiempoEntregaPromedioDias { get; set; } = default!;
    public decimal? PrecioPromedio { get; set; } = default!;
}
