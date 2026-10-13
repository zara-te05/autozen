namespace Autozen.Api.DTOs;

public class CrearProyectoRequestDto
{
    // Datos del Camión (Cada proyecto es un camión)
    public string Placas { get; set; } = string.Empty;
    public string? Marca { get; set; }
    public string? Modelo { get; set; }
    public DateTime? FechaEntrada { get; set; }
    public DateTime? TiempoEsperado { get; set; }
    public string? DanoEstimado { get; set; }

    // Datos del Cliente (Existente o Nuevo)
    public int? ClienteId { get; set; }
    public string? NombreCliente { get; set; }
    public string? ApellidoCliente { get; set; }
    public string? TelefonoCliente { get; set; }
    public string? LugarProcedencia { get; set; }

    // Datos de la Operación / Proyecto
    public int? UsuarioIdResponsable { get; set; }
    public DateTime? FechaEstimadaFinalizacion { get; set; }
}
