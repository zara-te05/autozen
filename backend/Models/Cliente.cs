namespace Autozen.Api.Models;

public class Cliente
{
    public int IdCliente { get; set; } = default!;
    public string Nombre { get; set; } = default!;
    public string Apellido { get; set; } = default!;
    public string NumTelefono { get; set; } = default!;
    public string? MetodoContactoAlternativo { get; set; } = default!;
    public string LugarProcedencia { get; set; } = default!;
}
