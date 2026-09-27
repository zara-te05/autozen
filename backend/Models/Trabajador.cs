namespace Autozen.Api.Models;

public class Trabajador
{
    public int IdTrabajador { get; set; } = default!;
    public string NombreTrabajador { get; set; } = default!;
    public string ApellidoTrabajador { get; set; } = default!;
    public decimal? SalarioTrabajador { get; set; } = default!;
}
