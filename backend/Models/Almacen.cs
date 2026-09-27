namespace Autozen.Api.Models;

public class Almacen
{
    public int IdAlmacen { get; set; } = default!;
    public string NombrePieza { get; set; } = default!;
    public int? CantidadStock { get; set; } = default!;
    public decimal? CostoPiezas { get; set; } = default!;
}
