namespace Autozen.Api.DTOs;

public class OrdenCompraDetalleResponseDto
{
    // Datos de la Compra
    public int IdCompra { get; set; }
    public int SolicitudCompraId { get; set; }
    public int OperacionId { get; set; }
    public string NombrePiezas { get; set; } = string.Empty;
    public int CantidadPiezas { get; set; }
    public decimal CostoPiezas { get; set; }

    // Datos del Proyecto y Vehículo
    public string PlacasCamion { get; set; } = string.Empty;
    public string? MarcaModeloCamion { get; set; }
    public string? NombreCliente { get; set; }

    // Datos del Proveedor y Tiempos Estimados
    public int? ProveedorId { get; set; }
    public string? NombreProveedor { get; set; }
    public string? ContactoProveedor { get; set; }
    public int? TiempoEntregaPromedioDias { get; set; }
    public DateTime FechaSolicitud { get; set; }
    public DateTime FechaEstimadaEntrega { get; set; }

    // Solicitante
    public string? SolicitadoPor { get; set; }
}
