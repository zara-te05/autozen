using System.ComponentModel.DataAnnotations;

namespace Autozen.Api.DTOs;

// =====================================================================
// Proyectos (camión en reparación)
// =====================================================================

public class EtapaProyectoDto
{
    [Required, MaxLength(60)]
    public string Nombre { get; set; } = string.Empty;

    [Range(1, 365, ErrorMessage = "Los días de cada etapa deben estar entre 1 y 365.")]
    public int DiasEstimados { get; set; }
}

public class RefaccionCotizadaDto
{
    [Required, MaxLength(120)]
    public string Nombre { get; set; } = string.Empty;

    [Range(1, 10000, ErrorMessage = "La cantidad de la refacción debe ser al menos 1.")]
    public int Cantidad { get; set; }
}

public class FotoProyectoDto
{
    public int Id { get; set; }
    public string Url { get; set; } = string.Empty;
    public DateTime FechaSubida { get; set; }
}

public class ProyectoTallerDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Tipo { get; set; } = "Cliente";
    public string NombreCamion { get; set; } = string.Empty;
    public string Placa { get; set; } = string.Empty;
    public string Cliente { get; set; } = string.Empty;
    public string? Aseguradora { get; set; }
    public string? NumeroSiniestro { get; set; }
    public string Responsable { get; set; } = string.Empty;
    public DateTime FechaIngreso { get; set; }
    public DateTime? FechaEntregaComprometida { get; set; }
    public int EtapaActual { get; set; }
    public bool Archivado { get; set; }
    public DateTime? FechaEvaluacion { get; set; }
    public string DescripcionDanos { get; set; } = string.Empty;
    public List<EtapaProyectoDto> Etapas { get; set; } = [];
    public List<RefaccionCotizadaDto> Refacciones { get; set; } = [];
    public List<FotoProyectoDto> Fotos { get; set; } = [];
    public List<DocumentoProyectoDto> Documentos { get; set; } = [];
}

/// <summary>Crear (desde la Evaluación de Daños) o editar un proyecto.</summary>
public class GuardarProyectoRequest
{
    /// <summary>"Cliente" o "Aseguradora". Al editar se conserva el tipo original.</summary>
    public string Tipo { get; set; } = "Cliente";

    [Required(ErrorMessage = "El nombre del camión es obligatorio."), MaxLength(120)]
    public string NombreCamion { get; set; } = string.Empty;

    [Required(ErrorMessage = "La placa es obligatoria."), MaxLength(20)]
    public string Placa { get; set; } = string.Empty;

    [MaxLength(120)] public string? Cliente { get; set; }
    [MaxLength(120)] public string? Aseguradora { get; set; }
    [MaxLength(60)] public string? NumeroSiniestro { get; set; }
    [MaxLength(120)] public string? Responsable { get; set; }

    public DateTime? FechaIngreso { get; set; }
    public DateTime? FechaEntregaComprometida { get; set; }

    [Range(0, 100)]
    public int EtapaActual { get; set; }

    public DateTime? FechaEvaluacion { get; set; }

    /// <summary>Al editar, null conserva el diagnóstico existente.</summary>
    public string? DescripcionDanos { get; set; }

    public List<EtapaProyectoDto> Etapas { get; set; } = [];

    /// <summary>Al editar, null conserva las refacciones existentes.</summary>
    public List<RefaccionCotizadaDto>? Refacciones { get; set; }
}

// =====================================================================
// Almacén
// =====================================================================

public class ArticuloDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public int? CategoriaId { get; set; }
    public string Categoria { get; set; } = string.Empty;
    public string Tipo { get; set; } = "Material";
    public string Unidad { get; set; } = "pieza";
    public decimal Existencia { get; set; }
    public decimal CostoUnitario { get; set; }
}

public class GuardarArticuloRequest
{
    [Required(ErrorMessage = "El nombre es obligatorio."), MaxLength(120)]
    public string Nombre { get; set; } = string.Empty;

    [Range(1, int.MaxValue, ErrorMessage = "Selecciona una categoría.")]
    public int CategoriaId { get; set; }

    /// <summary>"Material" (se consume) o "Herramienta" (se presta y debe volver).</summary>
    public string Tipo { get; set; } = "Material";

    /// <summary>pieza, kilogramo, litro, metro, juego o caja.</summary>
    public string Unidad { get; set; } = "pieza";

    [Range(0, 999999999, ErrorMessage = "La existencia no puede ser negativa.")]
    public decimal Existencia { get; set; }

    [Range(0, 999999999, ErrorMessage = "El costo no puede ser negativo.")]
    public decimal CostoUnitario { get; set; }
}

public class CategoriaAlmacenDto
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public int Articulos { get; set; }
}

public class GuardarCategoriaRequest
{
    [Required(ErrorMessage = "Escribe el nombre de la categoría."), MaxLength(60)]
    public string Nombre { get; set; } = string.Empty;
}

public class ValeMaterialDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public int ProyectoId { get; set; }
    public string ProyectoCodigo { get; set; } = string.Empty;
    public string ProyectoNombre { get; set; } = string.Empty;
    public int ArticuloId { get; set; }
    public string ArticuloNombre { get; set; } = string.Empty;
    public string Unidad { get; set; } = "pieza";
    public decimal Cantidad { get; set; }
    public decimal CostoUnitario { get; set; }
    public decimal Total { get; set; }
    public string EntregadoA { get; set; } = string.Empty;
    public DateTime Fecha { get; set; }
}

public class CrearValeMaterialRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Elige el proyecto.")]
    public int ProyectoId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Elige el material.")]
    public int ArticuloId { get; set; }

    [Range(0.001, 999999999, ErrorMessage = "La cantidad debe ser mayor a 0.")]
    public decimal Cantidad { get; set; }

    [MaxLength(120)]
    public string? EntregadoA { get; set; }
}

public class ValeHerramientaDto
{
    public int Id { get; set; }
    public string Codigo { get; set; } = string.Empty;
    public int ProyectoId { get; set; }
    public string ProyectoCodigo { get; set; } = string.Empty;
    public string ProyectoNombre { get; set; } = string.Empty;
    public int? ArticuloId { get; set; }
    public string ArticuloNombre { get; set; } = string.Empty;
    public string Unidad { get; set; } = "pieza";
    public decimal Cantidad { get; set; }
    public string EntregadoA { get; set; } = string.Empty;
    public DateTime FechaSalida { get; set; }
    public DateTime? FechaDevolucion { get; set; }
    public string? EstadoDevolucion { get; set; }
}

public class PrestarHerramientaRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Elige el proyecto.")]
    public int ProyectoId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Elige la herramienta.")]
    public int ArticuloId { get; set; }

    [Range(0.001, 999999999, ErrorMessage = "La cantidad debe ser mayor a 0.")]
    public decimal Cantidad { get; set; }

    [Required(ErrorMessage = "Indica quién se hace responsable."), MaxLength(120)]
    public string EntregadoA { get; set; } = string.Empty;
}

public class DevolverHerramientaRequest
{
    [Required, MaxLength(40)]
    public string Estado { get; set; } = "Buen estado";
}

// =====================================================================
// Compras y departamentos
// =====================================================================

/// <summary>Orden de compra en un solo paso (crea la solicitud y la orden).</summary>
public class CrearOrdenDirectaRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Elige el proyecto.")]
    public int OperacionId { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Elige el proveedor.")]
    public int ProveedorId { get; set; }

    [Required(ErrorMessage = "Describe las piezas."), MaxLength(200)]
    public string NombrePiezas { get; set; } = string.Empty;

    [Range(1, 100000, ErrorMessage = "La cantidad debe ser al menos 1.")]
    public int CantidadPiezas { get; set; }

    [Range(0, 999999999, ErrorMessage = "El costo no puede ser negativo.")]
    public decimal CostoPiezas { get; set; }
}

public class DepartamentoDto
{
    public int Id { get; set; }

    [Required(ErrorMessage = "El nombre es obligatorio."), MaxLength(80)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(120)]
    public string? Encargado { get; set; }

    [MaxLength(40)]
    public string Icono { get; set; } = "business";

    [Range(0, 10000, ErrorMessage = "El personal no puede ser negativo.")]
    public int Personal { get; set; }
}

// =====================================================================
// Solicitudes y órdenes de compra
// =====================================================================

public class PartidaOrdenDto
{
    [MaxLength(40)] public string? Articulo { get; set; }

    [Required(ErrorMessage = "Cada artículo necesita nombre."), MaxLength(200)]
    public string Nombre { get; set; } = string.Empty;

    [MaxLength(30)] public string Unidad { get; set; } = "Pieza";

    [Range(0.001, 999999999, ErrorMessage = "Las unidades deben ser mayores a 0.")]
    public decimal Unidades { get; set; }

    [Range(0, 999999999, ErrorMessage = "El precio no puede ser negativo.")]
    public decimal Precio { get; set; }

    [Range(0, 999999999, ErrorMessage = "El descuento no puede ser negativo.")]
    public decimal Descuento { get; set; }
}

public class OrdenCompraDocDto
{
    public string Folio { get; set; } = string.Empty;
    public DateTime Fecha { get; set; }
    public int? ProveedorId { get; set; }
    public string ProveedorNombre { get; set; } = string.Empty;
    public string ProveedorDireccion { get; set; } = string.Empty;
    public string Consignatario { get; set; } = string.Empty;
    public DateTime Entrega { get; set; }
    public string Condiciones { get; set; } = "Contado";
    public string ViaEmbarque { get; set; } = string.Empty;
    public List<PartidaOrdenDto> Partidas { get; set; } = [];
    public decimal TasaIva { get; set; } = 0.16m;
    public string Observaciones { get; set; } = string.Empty;
}

/// <summary>Lo que Compras llena para aprobar una solicitud.</summary>
public class AprobarSolicitudRequest
{
    public DateTime? Fecha { get; set; }

    [Range(1, int.MaxValue, ErrorMessage = "Elige el proveedor.")]
    public int ProveedorId { get; set; }

    [MaxLength(200)] public string? Consignatario { get; set; }
    public DateTime Entrega { get; set; }
    [MaxLength(40)] public string Condiciones { get; set; } = "Contado";
    [MaxLength(120)] public string? ViaEmbarque { get; set; }

    [MinLength(1, ErrorMessage = "Agrega al menos un artículo.")]
    public List<PartidaOrdenDto> Partidas { get; set; } = [];

    [Range(0, 1, ErrorMessage = "La tasa de IVA debe estar entre 0 y 1.")]
    public decimal TasaIva { get; set; } = 0.16m;

    public string? Observaciones { get; set; }
}

public class SolicitudCompraAppDto
{
    public int Id { get; set; }
    public int ProyectoId { get; set; }
    public string ProyectoCodigo { get; set; } = string.Empty;
    public string ProyectoNombre { get; set; } = string.Empty;
    public string SolicitadoPor { get; set; } = string.Empty;
    public DateTime Fecha { get; set; }
    public string Descripcion { get; set; } = string.Empty;
    public decimal Cantidad { get; set; }
    public string Unidad { get; set; } = "Pieza";
    public string Notas { get; set; } = string.Empty;
    public string Estado { get; set; } = "Pendiente";
    public string? MotivoRechazo { get; set; }
    public OrdenCompraDocDto? Orden { get; set; }
}

public class CrearSolicitudAppRequest
{
    [Range(1, int.MaxValue, ErrorMessage = "Elige el proyecto.")]
    public int ProyectoId { get; set; }

    [Required(ErrorMessage = "Escribe qué se necesita."), MaxLength(200)]
    public string Descripcion { get; set; } = string.Empty;

    [Range(0.001, 999999999, ErrorMessage = "La cantidad debe ser mayor a 0.")]
    public decimal Cantidad { get; set; } = 1;

    [MaxLength(30)] public string Unidad { get; set; } = "Pieza";
    public string? Notas { get; set; }
}

public class RechazarSolicitudRequest
{
    [Required(ErrorMessage = "Indica el motivo del rechazo.")]
    public string Motivo { get; set; } = string.Empty;
}

// =====================================================================
// Documentos, resguardos y avisos
// =====================================================================

public class DocumentoProyectoDto
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public long Tamano { get; set; }
    public DateTime FechaSubida { get; set; }
}

public class ResguardoDto
{
    public int Id { get; set; }

    [Required(ErrorMessage = "Indica la empresa."), MaxLength(120)]
    public string Empresa { get; set; } = string.Empty;

    [MaxLength(60)] public string? TipoUnidad { get; set; }
    [MaxLength(40)] public string? NumeroUnidad { get; set; }

    [Required(ErrorMessage = "Indica qué se entrega.")]
    public string Objetos { get; set; } = string.Empty;

    public DateTime FechaIngreso { get; set; }

    [Required(ErrorMessage = "Indica el operador que entrega."), MaxLength(120)]
    public string Operador { get; set; } = string.Empty;

    /// <summary>Firma del operador: PNG en base64 (máx. ~300 KB).</summary>
    [MaxLength(400_000)]
    public string? Firma { get; set; }

    public DateTime? FechaSalida { get; set; }
    public string? EntregadoA { get; set; }
    public string? NotasSalida { get; set; }
}

public class SalidaResguardoRequest
{
    [Required(ErrorMessage = "Indica a quién se le entrega."), MaxLength(120)]
    public string EntregadoA { get; set; } = string.Empty;

    public string? Notas { get; set; }
}

public class AvisoDto
{
    public long Id { get; set; }
    public string Tipo { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string Mensaje { get; set; } = string.Empty;
    public DateTime Fecha { get; set; }
}
