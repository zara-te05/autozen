namespace Autozen.Api;

/// <summary>
/// Roles del sistema Autozen.
/// </summary>
public static class Roles
{
    public const string Admin = "Admin";                  // Privilegios en todas las áreas
    public const string ProyectoLider = "Proyecto_Lider"; // Jefe de departamento: Taller / Proyectos
    public const string ComprasAdmin = "Compras_Admin";   // Jefe de departamento: Compras
    public const string AlmacenAdmin = "Almacen_Admin";   // Jefe de departamento: Almacén
    public const string EvaluacionAdmin = "Evaluacion_Admin"; // Jefe de departamento: Evaluación (Recepción)
    public const string Usuario = "Usuario";              // Rol base

    public static readonly string[] Todos = [Admin, ProyectoLider, ComprasAdmin, AlmacenAdmin, EvaluacionAdmin, Usuario];
}

/// <summary>
/// Quién puede escribir (crear, editar, eliminar) en cada departamento.
/// Leer está permitido a cualquier usuario autenticado, salvo Trabajador (solo Admin).
/// Proyectos cubre proyectos a personas y a aseguradoras (comparten tablas).
/// </summary>
public static class Edicion
{
    public const string Proyectos = Roles.Admin + "," + Roles.ProyectoLider;
    public const string Compras = Roles.Admin + "," + Roles.ComprasAdmin;
    public const string Almacen = Roles.Admin + "," + Roles.AlmacenAdmin;
    public const string Evaluacion = Roles.Admin + "," + Roles.EvaluacionAdmin;

    /// <summary>Crear proyectos (desde la Evaluación de Daños) y subir sus fotos.</summary>
    public const string CrearProyecto = Roles.Admin + "," + Roles.ProyectoLider + "," + Roles.EvaluacionAdmin;

    /// <summary>Solicitar compras para un proyecto.</summary>
    public const string SolicitarCompra = Roles.Admin + "," + Roles.ProyectoLider + "," + Roles.ComprasAdmin;

    /// <summary>Vales de material y préstamos de herramienta.</summary>
    public const string ValesAlmacen = Roles.Admin + "," + Roles.AlmacenAdmin + "," + Roles.ProyectoLider;
}

/// <summary>
/// Nombres de políticas de autorización y de rate limiting.
/// </summary>
public static class Politicas
{
    public const string AltaUsuarios = "AltaUsuarios";
    public const string Login = "Login";
}

/// <summary>
/// Áreas (departamentos) del taller. Cada jefe pertenece al área de su rol y cada usuario con rol
/// 'Usuario' pertenece al área del jefe que lo dio de alta. El Admin no tiene área: ve todo.
/// </summary>
public static class Areas
{
    public const string Proyectos = "Proyectos";
    public const string Compras = "Compras";
    public const string Almacen = "Almacen";
    public const string Evaluacion = "Evaluacion";

    public static readonly string[] Todas = [Proyectos, Compras, Almacen, Evaluacion];

    /// <summary>Nombre del claim del JWT con el área del usuario.</summary>
    public const string Claim = "area";

    /// <summary>Área que le corresponde a un rol de jefe; null para Admin y Usuario.</summary>
    public static string? DeRol(string? rol) => rol switch
    {
        Roles.ProyectoLider => Proyectos,
        Roles.ComprasAdmin => Compras,
        Roles.AlmacenAdmin => Almacen,
        Roles.EvaluacionAdmin => Evaluacion,
        _ => null,
    };

    public static string? Normalizar(string? area) =>
        string.IsNullOrWhiteSpace(area) ? null : Todas.FirstOrDefault(a => a.Equals(area.Trim(), StringComparison.OrdinalIgnoreCase));

    public static bool EsJefe(string? rol) => DeRol(rol) is not null;
}

/// <summary>
/// Políticas de LECTURA por área:
/// - Admin y jefes de departamento: leen todas las áreas.
/// - Rol 'Usuario': solo lee su propia área (claim "area").
/// La ESCRITURA sigue limitada por <see cref="Edicion"/> (cada jefe en su área; Admin en todo).
/// </summary>
public static class Lectura
{
    public const string Proyectos = "Leer_Proyectos";
    public const string Compras = "Leer_Compras";
    public const string Almacen = "Leer_Almacen";
    public const string Evaluacion = "Leer_Evaluacion";

    /// <summary>Qué áreas de usuario pueden leer cada política. La evaluación de daños vive dentro del proyecto.</summary>
    public static readonly IReadOnlyDictionary<string, string[]> AreasPorPolitica = new Dictionary<string, string[]>
    {
        [Proyectos] = [Areas.Proyectos, Areas.Evaluacion],
        [Evaluacion] = [Areas.Evaluacion, Areas.Proyectos],
        [Compras] = [Areas.Compras],
        [Almacen] = [Areas.Almacen],
    };

    public static bool Permite(System.Security.Claims.ClaimsPrincipal usuario, string[] areas)
    {
        if (usuario.Identity?.IsAuthenticated != true) return false;
        if (usuario.IsInRole(Roles.Admin)) return true;
        if (usuario.IsInRole(Roles.ProyectoLider) || usuario.IsInRole(Roles.ComprasAdmin) ||
            usuario.IsInRole(Roles.AlmacenAdmin) || usuario.IsInRole(Roles.EvaluacionAdmin)) return true;
        var area = usuario.FindFirst(Areas.Claim)?.Value;
        return area is not null && areas.Contains(area);
    }
}
