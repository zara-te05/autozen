namespace Autozen.Api.DTOs;

public class ProyectoDetalleResponseDto
{
    // Identificador principal del Proyecto
    public int IdProyecto { get; set; } // Mapea a IdOperacion

    // Datos del Camión
    public int IdCamion { get; set; }
    public string Placas { get; set; } = string.Empty;
    public string? Marca { get; set; }
    public string? Modelo { get; set; }
    public DateTime FechaEntrada { get; set; }
    public DateTime TiempoEsperado { get; set; }
    public string? DanoEstimado { get; set; }

    // Datos del Cliente asociado
    public int IdCliente { get; set; }
    public string NombreCliente { get; set; } = string.Empty;
    public string? ApellidoCliente { get; set; }
    public string? TelefonoCliente { get; set; }
    public string? LugarProcedencia { get; set; }

    // Datos de la Operación / Estado de Trabajo
    public int? UsuarioIdResponsable { get; set; }
    public string? NombreResponsable { get; set; }
    public DateTime FechaInicio { get; set; }
    public DateTime FechaEstimadaFinalizacion { get; set; }
    public string EstadoOperacion { get; set; } = "Iniciado";

    // Solicitud de baja
    public bool SolicitaEliminacion { get; set; }
    public string? MotivoEliminacion { get; set; }
}
