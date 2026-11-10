using System.Text.RegularExpressions;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;

namespace Autozen.Api.Services;

/// <summary>Quién hace la petición: su rol y su área (del JWT).</summary>
public sealed record Solicitante(string Rol, string? Area)
{
    public bool EsAdmin => Rol == Roles.Admin;
    public bool EsJefe => Areas.EsJefe(Rol);
}

/// <summary>
/// Gestión de usuarios con permisos por área:
/// - Admin: CRUD de cualquier usuario y rol en todo el sistema.
/// - Jefe de departamento: CRUD solo de usuarios con rol 'Usuario' de SU área; los usuarios que da de alta
///   quedan en su área y solo pueden leer esa área.
/// </summary>
public partial class UsuarioAdminService
{
    public const int PasswordMinimo = 8;
    public const int PasswordMaximo = 64;
    public const string MensajePassword =
        "La contraseña debe tener entre 8 y 64 caracteres, solo letras y números (sin espacios, acentos ni signos), con al menos una letra y un número.";

    [GeneratedRegex("^(?=.*[A-Za-z])(?=.*[0-9])[A-Za-z0-9]{8,64}$")]
    private static partial Regex PasswordValida();

    private readonly IUsuarioRepository _usuarioRepo;

    public UsuarioAdminService(IUsuarioRepository usuarioRepo)
    {
        _usuarioRepo = usuarioRepo;
    }

    public static void ValidarPassword(string? password)
    {
        if (password is null || !PasswordValida().IsMatch(password))
            throw new InvalidOperationException(MensajePassword);
    }

    /// <summary>Lista los usuarios que el solicitante puede administrar (sin exponer contraseñas).</summary>
    public async Task<IEnumerable<UsuarioDetalleResponseDto>> GetAllAsync(Solicitante solicitante)
    {
        var usuarios = await _usuarioRepo.GetAllAsync();
        return usuarios.Where(u => PuedeAdministrar(solicitante, u)).OrderBy(u => u.Nombre).Select(ADto);
    }

    public async Task<UsuarioDetalleResponseDto?> GetByIdAsync(int id, Solicitante solicitante)
    {
        var u = await _usuarioRepo.GetByIdAsync(id);
        return u is null || !PuedeAdministrar(solicitante, u) ? null : ADto(u);
    }

    /// <summary>
    /// Alta de usuario. El Admin asigna cualquier rol (y el área si es 'Usuario');
    /// un jefe solo crea usuarios con rol 'Usuario' y quedan en su área.
    /// </summary>
    public async Task<UsuarioDetalleResponseDto> CrearUsuarioConPrivilegiosAsync(CrearUsuarioAdminRequestDto dto, Solicitante solicitante)
    {
        if (string.IsNullOrWhiteSpace(dto.Nombre) || string.IsNullOrWhiteSpace(dto.Username) || string.IsNullOrWhiteSpace(dto.Password))
            throw new InvalidOperationException("Nombre, nombre de usuario y contraseña son requeridos.");

        ValidarPassword(dto.Password);

        var (rol, area) = ResolverRolYArea(dto.Rol, dto.Area, solicitante);

        if (await _usuarioRepo.GetByUsername(dto.Username.Trim()) != null)
            throw new InvalidOperationException($"El nombre de usuario '{dto.Username.Trim()}' ya está en uso.");

        var creado = await _usuarioRepo.CreateAsync(new CreateUsuarioDto
        {
            Nombre = dto.Nombre.Trim(),
            Username = dto.Username.Trim(),
            Password = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Rol = rol,
            Area = area,
            PuestoTrabajo = dto.PuestoTrabajo?.Trim(),
            TrabajadorId = dto.TrabajadorId,
            MetodoContacto = dto.MetodoContacto?.Trim()
        });
        return ADto(creado);
    }

    /// <summary>Asignación rápida de rol y área (solo Admin).</summary>
    public async Task<bool> ActualizarPrivilegiosAsync(int id, ActualizarPrivilegiosRequestDto dto, Solicitante solicitante)
    {
        if (!solicitante.EsAdmin) throw new UnauthorizedAccessException("Solo el Administrador puede cambiar privilegios.");
        var actual = await _usuarioRepo.GetByIdAsync(id);
        if (actual == null) return false;

        var (rol, area) = ResolverRolYArea(dto.Rol, dto.Area ?? actual.Area, solicitante);
        ProtegerAdminPrincipal(actual, rol);

        return await _usuarioRepo.UpdateAsync(id, new CreateUsuarioDto
        {
            Nombre = actual.Nombre,
            Username = actual.Username,
            Password = actual.Password, // Conserva el hash actual
            Rol = rol,
            Area = area,
            PuestoTrabajo = dto.PuestoTrabajo?.Trim() ?? actual.PuestoTrabajo,
            TrabajadorId = dto.TrabajadorId ?? actual.TrabajadorId,
            MetodoContacto = actual.MetodoContacto
        });
    }

    /// <summary>Edición del usuario, con opción de cambiar contraseña. Un jefe solo edita usuarios de su área.</summary>
    public async Task<bool> EditarUsuarioAsync(int id, EditarUsuarioAdminRequestDto dto, Solicitante solicitante)
    {
        var actual = await _usuarioRepo.GetByIdAsync(id);
        if (actual == null || !PuedeAdministrar(solicitante, actual)) return false;

        if (string.IsNullOrWhiteSpace(dto.Nombre) || string.IsNullOrWhiteSpace(dto.Username))
            throw new InvalidOperationException("Nombre y nombre de usuario son requeridos.");

        var cambiaPassword = !string.IsNullOrEmpty(dto.Password);
        if (cambiaPassword) ValidarPassword(dto.Password);

        var username = dto.Username.Trim();
        if (!username.Equals(actual.Username, StringComparison.OrdinalIgnoreCase))
        {
            var otro = await _usuarioRepo.GetByUsername(username);
            if (otro != null && otro.IdUsuario != id)
                throw new InvalidOperationException($"El nombre de usuario '{username}' ya está en uso.");
        }

        var (rol, area) = ResolverRolYArea(dto.Rol, dto.Area ?? actual.Area, solicitante);
        ProtegerAdminPrincipal(actual, rol);

        return await _usuarioRepo.UpdateAsync(id, new CreateUsuarioDto
        {
            Nombre = dto.Nombre.Trim(),
            Username = username,
            Password = cambiaPassword ? BCrypt.Net.BCrypt.HashPassword(dto.Password!) : actual.Password,
            Rol = rol,
            Area = area,
            PuestoTrabajo = dto.PuestoTrabajo?.Trim(),
            TrabajadorId = dto.TrabajadorId,
            MetodoContacto = dto.MetodoContacto?.Trim()
        });
    }

    /// <summary>Baja de usuario. Protege la cuenta 'admin'. Un jefe solo elimina usuarios de su área.</summary>
    public async Task<bool> EliminarUsuarioAsync(int id, Solicitante solicitante)
    {
        var actual = await _usuarioRepo.GetByIdAsync(id);
        if (actual == null || !PuedeAdministrar(solicitante, actual)) return false;

        if (actual.Username.Equals("admin", StringComparison.OrdinalIgnoreCase))
            throw new InvalidOperationException("No se puede eliminar la cuenta principal de administrador ('admin').");

        return await _usuarioRepo.DeleteAsync(id);
    }

    // ------------------------------------------------------------------

    /// <summary>Admin administra a todos; un jefe solo a los usuarios con rol 'Usuario' de su área.</summary>
    private static bool PuedeAdministrar(Solicitante s, Usuario u) =>
        s.EsAdmin || (s.EsJefe && u.Rol == Roles.Usuario && u.Area is not null && u.Area == Areas.DeRol(s.Rol));

    /// <summary>
    /// Rol y área finales:
    /// - Jefe solicitante: siempre rol 'Usuario' en el área del jefe.
    /// - Admin: el rol pedido; los jefes toman el área de su rol, el Admin ninguna y 'Usuario' la que se indique (obligatoria).
    /// </summary>
    private static (string Rol, string? Area) ResolverRolYArea(string? rolPedido, string? areaPedida, Solicitante s)
    {
        var rol = ValidarYNormalizarRol(rolPedido);

        if (!s.EsAdmin)
        {
            if (!s.EsJefe) throw new UnauthorizedAccessException("No tienes permiso para administrar usuarios.");
            if (rol != Roles.Usuario) throw new UnauthorizedAccessException("Solo el Administrador puede asignar roles distintos a 'Usuario'.");
            return (Roles.Usuario, Areas.DeRol(s.Rol));
        }

        if (rol == Roles.Admin) return (rol, null);
        if (Areas.DeRol(rol) is { } areaJefe) return (rol, areaJefe);

        var area = Areas.Normalizar(areaPedida)
            ?? throw new InvalidOperationException($"Indica el área del usuario: {string.Join(", ", Areas.Todas)}.");
        return (rol, area);
    }

    private static void ProtegerAdminPrincipal(Usuario actual, string rolNuevo)
    {
        if (actual.Username.Equals("admin", StringComparison.OrdinalIgnoreCase) && rolNuevo != Roles.Admin)
            throw new InvalidOperationException("La cuenta principal 'admin' debe conservar el rol de Administrador.");
    }

    private static string ValidarYNormalizarRol(string? rol)
    {
        if (string.IsNullOrWhiteSpace(rol))
            return Roles.Usuario;

        string r = rol.Trim();
        return Roles.Todos.FirstOrDefault(val => val.Equals(r, StringComparison.OrdinalIgnoreCase))
            ?? throw new InvalidOperationException($"El rol '{r}' no es válido. Roles permitidos: {string.Join(", ", Roles.Todos)}.");
    }

    private static UsuarioDetalleResponseDto ADto(Usuario u) => new()
    {
        IdUsuario = u.IdUsuario,
        Nombre = u.Nombre,
        Username = u.Username,
        Rol = u.Rol,
        Area = u.Area,
        PuestoTrabajo = u.PuestoTrabajo,
        TrabajadorId = u.TrabajadorId,
        MetodoContacto = u.MetodoContacto
    };
}
