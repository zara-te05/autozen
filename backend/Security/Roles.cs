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
