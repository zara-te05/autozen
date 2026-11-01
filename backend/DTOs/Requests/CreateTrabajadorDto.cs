using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateTrabajadorDto
{
    public string NombreTrabajador { get; set; } = default!;
    public string ApellidoTrabajador { get; set; } = default!;
    [Range(1, double.MaxValue, ErrorMessage = "SalarioTrabajador debe ser mayor o igual a 1.")]
    public decimal? SalarioTrabajador { get; set; } = default!;
}
