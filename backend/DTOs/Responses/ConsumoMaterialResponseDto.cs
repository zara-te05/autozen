namespace Autozen.Api.DTOs;

public class ConsumoMaterialResponseDto
{
    public int IdSolicitudAlmacen { get; set; }
    public int OperacionId { get; set; }
    public int IdAlmacen { get; set; }
    public string NombrePieza { get; set; } = string.Empty;
    public int CantidadConsumida { get; set; }
    public decimal CostoUnitario { get; set; }
    public decimal TotalACobrar { get; set; }
    public int StockRestante { get; set; }
    public DateTime FechaConsumo { get; set; }
}
