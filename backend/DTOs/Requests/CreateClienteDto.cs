namespace Autozen.Api.DTOs;

public class CreateClienteDto
{
    public string Nombre { get; set; } = default!;
    public string Apellido { get; set; } = default!;
    public string NumTelefono { get; set; } = default!;
    public string? MetodoContactoAlternativo { get; set; } = default!;
    public string LugarProcedencia { get; set; } = default!;
}
