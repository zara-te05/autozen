using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateProveedorDto
{
    public string NombreProveedor { get; set; } = default!;
    public string? Contacto { get; set; } = default!;
    [MaxLength(250)]
    public string? Direccion { get; set; }
    [Range(0, int.MaxValue, ErrorMessage = "TiempoEntregaPromedioDias debe ser mayor o igual a 0.")]
    public int? TiempoEntregaPromedioDias { get; set; } = default!;
    [Range(0, double.MaxValue, ErrorMessage = "PrecioPromedio debe ser mayor o igual a 0.")]
    public decimal? PrecioPromedio { get; set; } = default!;
}
