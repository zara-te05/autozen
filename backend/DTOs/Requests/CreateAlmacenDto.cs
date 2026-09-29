namespace Autozen.Api.DTOs;

public class CreateAlmacenDto
{
    public string NombrePieza { get; set; } = default!;
    public int? CantidadStock { get; set; } = default!;
    public decimal? CostoPiezas { get; set; } = default!;
}
