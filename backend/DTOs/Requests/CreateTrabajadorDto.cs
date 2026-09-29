namespace Autozen.Api.DTOs;

public class CreateTrabajadorDto
{
    public string NombreTrabajador { get; set; } = default!;
    public string ApellidoTrabajador { get; set; } = default!;
    public decimal? SalarioTrabajador { get; set; } = default!;
}
