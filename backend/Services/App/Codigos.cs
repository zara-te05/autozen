namespace Autozen.Api.Services;

/// <summary>Códigos legibles que muestra la app (PC-001, ALM-004, VM-0012...).</summary>
internal static class Codigos
{
    public const string Cliente = "Cliente";
    public const string Aseguradora = "Aseguradora";

    public static string Proyecto(string tipo, int id) => (tipo == Aseguradora ? "PA-" : "PC-") + id.ToString("D3");
    public static string Articulo(int id) => "ALM-" + id.ToString("D3");
    public static string ValeMaterial(int id) => "VM-" + id.ToString("D4");
    public static string ValeHerramienta(int id) => "VH-" + id.ToString("D4");

    /// <summary>Nombre del camión para SQL (alias "c" = CAMION): nombre libre o marca + modelo.</summary>
    public const string NombreCamionSql = "COALESCE(NULLIF(c.nombre, ''), NULLIF(TRIM(COALESCE(c.marca, '') || ' ' || COALESCE(c.modelo, '')), ''), 'Camión')";
}
