using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Autozen.Api.Repositories;

namespace Autozen.Api.Services;

public class UsuarioService
{
    private readonly IUsuarioRepository _usuarioRepo;

    public UsuarioService(IUsuarioRepository usuarioRepo)
    {
        _usuarioRepo = usuarioRepo;
    }

    public async Task<IEnumerable<Usuario>> GetAllAsync()
    {
        var usuarios = await _usuarioRepo.GetAllAsync();

        //Es una buena practica *N U N C A* enviar las passwords haseahas al front
        foreach(var u in usuarios)
        {
            u.Password = string.Empty;
        }

        return usuarios;
    }

    public async Task<Usuario?> GetByIdAsync(int id)
    {
        var usuario = await _usuarioRepo.GetByIdAsync(id);
        
        if( usuario != null)
        {
            usuario.Password = string.Empty;
        }
        return usuario;
    }

    public async Task<Usuario?> GetByName(string nombre)
    {
        var usuario = await _usuarioRepo.GetByUsername(nombre);

        if(usuario != null)
        {
            usuario.Password = string.Empty;
        }

        return usuario;
    }

    public async Task<Usuario> CrearUsuario(CreateUsuarioDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.Username) || 
            string.IsNullOrWhiteSpace(dto.Password) || 
            string.IsNullOrWhiteSpace(dto.Rol))
        {
            throw new InvalidOperationException($"No pueden permanecer campos criticos en blanco");
        }
        
        var existente = await _usuarioRepo.GetByUsername(dto.Username);

        // Validamos que no exista otro usuario igual
        if(existente != null)
        {
            throw new InvalidOperationException($"El nombre de usuario: {dto.Username} ya esta en uso.");
        }
        
        // Hasheamos la password
        dto.Password = BCrypt.Net.BCrypt.HashPassword(dto.Password);

        // Guardar en postgres
        var usuarioNuevo = await _usuarioRepo.CreateAsync(dto);
        usuarioNuevo.Password = string.Empty; // Limpiamos para la respuesta
        return usuarioNuevo;
    }

    public async Task<bool> UpdateAsync(int id, CreateUsuarioDto dto)
    {
        // Hay que buscar al usuario
        var usuarioActual = await _usuarioRepo.GetByIdAsync(id);
        
        if(usuarioActual == null)
        {
            return false; // No se encontro    
        }

        // Si se cambio la contrasena, hay que actualizarla
        if (!string.IsNullOrWhiteSpace(dto.Password))
        {
            dto.Password = BCrypt.Net.BCrypt.HashPassword(dto.Password);
        }
        else
        {
            // Si no se envio una password nueva, conservamos la vieja
            dto.Password = usuarioActual.Password;
        }

        // Ahora si vamos a actualizar
        return await _usuarioRepo.UpdateAsync(id, dto);
    }

    public async Task<bool> EliminarAsync(int id)
    {
        var usuario = await _usuarioRepo.GetByIdAsync(id);
        if (usuario == null)
        {
            return false;
        }

        // Regla de ejemplo: no permitir borrar al admin principal
        if (usuario.Username.ToLower() == "admin")
        {
            throw new InvalidOperationException("No se puede eliminar el usuario administrador principal.");
        }

        return await _usuarioRepo.DeleteAsync(id);
    }

}
