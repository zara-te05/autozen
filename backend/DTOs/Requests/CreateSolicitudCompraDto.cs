using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateSolicitudCompraDto
{
    public int OperacionId { get; set; } = default!;
    public int? UsuarioId { get; set; } = default!;
    public int? ProveedorId { get; set; } = default!;
    public string? NombrePiezasCotizadas { get; set; } = default!;
    [Range(1, int.MaxValue, ErrorMessage = "CantidadPiezasCotizadas debe ser mayor o igual a 1.")]
    public int? CantidadPiezasCotizadas { get; set; } = default!;
    public DateTime FechaSolicitud { get; set; } = default!;
}
