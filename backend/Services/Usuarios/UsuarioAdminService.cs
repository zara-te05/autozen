using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;

namespace Autozen.Api.Services;

public class UsuarioAdminService
{
    private readonly IUsuarioRepository _usuarioRepo;

    public UsuarioAdminService(IUsuarioRepository usuarioRepo)
    {
        _usuarioRepo = usuarioRepo;
    }

    /// <summary>
    /// Lista todos los usuarios del sistema sin exponer hashes de contraseñas.
    /// </summary>
    public async Task<IEnumerable<UsuarioDetalleResponseDto>> GetAllAsync()
    {
        var usuarios = await _usuarioRepo.GetAllAsync();
        return usuarios.Select(u => new UsuarioDetalleResponseDto
        {
            IdUsuario = u.IdUsuario,
            Nombre = u.Nombre,
            Username = u.Username,
            Rol = u.Rol,
            PuestoTrabajo = u.PuestoTrabajo,
            TrabajadorId = u.TrabajadorId,
            MetodoContacto = u.MetodoContacto
        });
    }

    /// <summary>
    /// Obtiene un usuario específico por su ID sin exponer contraseña.
    /// </summary>
    public async Task<UsuarioDetalleResponseDto?> GetByIdAsync(int id)
    {
        var u = await _usuarioRepo.GetByIdAsync(id);
        if (u == null)
            return null;

        return new UsuarioDetalleResponseDto
        {
            IdUsuario = u.IdUsuario,
            Nombre = u.Nombre,
            Username = u.Username,
            Rol = u.Rol,
            PuestoTrabajo = u.PuestoTrabajo,
            TrabajadorId = u.TrabajadorId,
            MetodoContacto = u.MetodoContacto
        };
    }

    /// <summary>
    /// Alta de usuario. El Administrador puede asignar cualquier rol; un jefe de departamento
    /// solo puede dar de alta usuarios con el rol base 'Usuario'.
    /// </summary>
    public async Task<UsuarioDetalleResponseDto> CrearUsuarioConPrivilegiosAsync(CrearUsuarioAdminRequestDto dto, bool solicitanteEsAdmin)
    {
        if (string.IsNullOrWhiteSpace(dto.Nombre) ||
            string.IsNullOrWhiteSpace(dto.Username) ||
            string.IsNullOrWhiteSpace(dto.Password))
        {
            throw new InvalidOperationException("Nombre, nombre de usuario y contraseña son requeridos.");
        }

        if (dto.Password.Length < 8)
        {
            throw new InvalidOperationException("La contraseña debe tener al menos 8 caracteres.");
        }

        string rolAsignado = ValidarYNormalizarRol(dto.Rol);
        if (!solicitanteEsAdmin && rolAsignado != Roles.Usuario)
        {
            throw new UnauthorizedAccessException("Solo el Administrador puede asignar roles distintos a 'Usuario'.");
        }

        var existente = await _usuarioRepo.GetByUsername(dto.Username.Trim());
        if (existente != null)
        {
            throw new InvalidOperationException($"El nombre de usuario '{dto.Username}' ya está en uso.");
        }

        string passwordHash = BCrypt.Net.BCrypt.HashPassword(dto.Password);

        var nuevoDto = new CreateUsuarioDto
        {
            Nombre = dto.Nombre.Trim(),
            Username = dto.Username.Trim(),
            Password = passwordHash,
            Rol = rolAsignado,
            PuestoTrabajo = dto.PuestoTrabajo?.Trim(),
            TrabajadorId = dto.TrabajadorId,
            MetodoContacto = dto.MetodoContacto?.Trim()
        };

        var creado = await _usuarioRepo.CreateAsync(nuevoDto);

        return new UsuarioDetalleResponseDto
        {
            IdUsuario = creado.IdUsuario,
            Nombre = creado.Nombre,
            Username = creado.Username,
            Rol = creado.Rol,
            PuestoTrabajo = creado.PuestoTrabajo,
            TrabajadorId = creado.TrabajadorId,
            MetodoContacto = creado.MetodoContacto
        };
    }

    /// <summary>
    /// Asignación rápida de privilegios por área (Rol, Puesto de Trabajo y Vinculación a Trabajador).
    /// </summary>
    public async Task<bool> ActualizarPrivilegiosAsync(int id, ActualizarPrivilegiosRequestDto dto)
    {
        var actual = await _usuarioRepo.GetByIdAsync(id);
        if (actual == null)
            return false;

        string rolValidado = ValidarYNormalizarRol(dto.Rol);

        var updateDto = new CreateUsuarioDto
        {
            Nombre = actual.Nombre,
            Username = actual.Username,
            Password = actual.Password, // Conserva el hash actual
            Rol = rolValidado,
            PuestoTrabajo = dto.PuestoTrabajo?.Trim() ?? actual.PuestoTrabajo,
            TrabajadorId = dto.TrabajadorId ?? actual.TrabajadorId,
            MetodoContacto = actual.MetodoContacto
        };

        return await _usuarioRepo.UpdateAsync(id, updateDto);
    }

    /// <summary>
    /// Edición general del usuario por el Administrador con opción de cambiar contraseña.
    /// </summary>
    public async Task<bool> EditarUsuarioAsync(int id, EditarUsuarioAdminRequestDto dto)
    {
        var actual = await _usuarioRepo.GetByIdAsync(id);
        if (actual == null)
            return false;

        if (!string.IsNullOrWhiteSpace(dto.Password) && dto.Password.Length < 8)
        {
            throw new InvalidOperationException("La contraseña debe tener al menos 8 caracteres.");
        }

        string passwordFinal = string.IsNullOrWhiteSpace(dto.Password)
            ? actual.Password
            : BCrypt.Net.BCrypt.HashPassword(dto.Password);

        string rolValidado = ValidarYNormalizarRol(dto.Rol);

        var updateDto = new CreateUsuarioDto
        {
            Nombre = dto.Nombre.Trim(),
            Username = dto.Username.Trim(),
            Password = passwordFinal,
            Rol = rolValidado,
            PuestoTrabajo = dto.PuestoTrabajo?.Trim(),
            TrabajadorId = dto.TrabajadorId,
            MetodoContacto = dto.MetodoContacto?.Trim()
        };

        return await _usuarioRepo.UpdateAsync(id, updateDto);
    }

    /// <summary>
    /// Eliminación segura de usuario por el Administrador. Protege la cuenta root 'admin'.
    /// </summary>
    public async Task<bool> EliminarUsuarioAsync(int id)
    {
        var actual = await _usuarioRepo.GetByIdAsync(id);
        if (actual == null)
            return false;

        if (actual.Username.Equals("admin", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("No se puede eliminar la cuenta principal de administrador ('admin').");
        }

        return await _usuarioRepo.DeleteAsync(id);
    }

    private static string ValidarYNormalizarRol(string? rol)
    {
        if (string.IsNullOrWhiteSpace(rol))
            return Roles.Usuario;

        string r = rol.Trim();
        return Roles.Todos.FirstOrDefault(val => val.Equals(r, StringComparison.OrdinalIgnoreCase))
            ?? throw new InvalidOperationException($"El rol '{r}' no es válido. Roles permitidos: {string.Join(", ", Roles.Todos)}.");
    }
}
