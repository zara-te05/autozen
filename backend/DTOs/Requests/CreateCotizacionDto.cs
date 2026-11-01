using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

public class CreateCotizacionDto : IValidatableObject
{
    public int OperacionId { get; set; } = default!;
    public int? TrabajadorId { get; set; } = default!;
    [Range(1, double.MaxValue, ErrorMessage = "ManoObraEstimada debe ser mayor o igual a 1.")]
    public decimal? ManoObraEstimada { get; set; } = default!;
    [Range(0, double.MaxValue, ErrorMessage = "CostoEstimadoPiezas debe ser mayor o igual a 0.")]
    public decimal? CostoEstimadoPiezas { get; set; } = default!;
    [Range(0, double.MaxValue, ErrorMessage = "Total debe ser mayor o igual a 0.")]
    public decimal? Total { get; set; } = default!;
    public string? EstadoCotizacion { get; set; } = default!;

    public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
    {
        if (Total.HasValue && Total < (ManoObraEstimada ?? 0) + (CostoEstimadoPiezas ?? 0))
        {
            yield return new ValidationResult(
                "El total no puede ser menor que la mano de obra más el costo de las piezas.",
                [nameof(Total)]);
        }
    }
}
