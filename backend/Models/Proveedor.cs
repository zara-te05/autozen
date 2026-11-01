namespace Autozen.Api.Models;

public class Proveedor
{
    public int IdProveedor { get; set; } = default!;
    public string NombreProveedor { get; set; } = default!;
    public string? Contacto { get; set; } = default!;
    public string? Direccion { get; set; }
    public int? TiempoEntregaPromedioDias { get; set; } = default!;
    public decimal? PrecioPromedio { get; set; } = default!;
}
