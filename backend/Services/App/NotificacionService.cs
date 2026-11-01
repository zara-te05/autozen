using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Dapper;

namespace Autozen.Api.Services;

/// <summary>
/// Avisos de eventos para cada rol (parte "servidor" del esquema híbrido de notificaciones).
/// Solo se guardan eventos; lo que la app puede calcular (stock bajo, retrasos, entregas próximas,
/// herramientas sin devolver) lo calcula el teléfono para no cargar al backend.
/// </summary>
public class NotificacionService
{
    private const int DiasConservar = 60;
    private readonly DapperContext _db;
    private readonly ILogger<NotificacionService> _logger;

    public NotificacionService(DapperContext db, ILogger<NotificacionService> logger)
    {
        _db = db;
        _logger = logger;
    }

    /// <summary>Registra el evento para cada rol. Si falla, solo se registra en el log: nunca rompe la operación principal.</summary>
    public async Task RegistrarAsync(string tipo, string titulo, string mensaje, params string[] roles)
    {
        try
        {
            foreach (var rol in roles.Distinct())
            {
                await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
                    "INSERT INTO NOTIFICACION (rol_destino, tipo, titulo, mensaje) VALUES (@Rol, @Tipo, @Titulo, @Mensaje);",
                    new { Rol = rol, Tipo = tipo, Titulo = titulo, Mensaje = mensaje }, transaction: tx));
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "No se pudo registrar el aviso {Tipo}", tipo);
        }
    }

    public async Task<List<AvisoDto>> ListarAsync(string rol)
    {
        // Limpieza barata de avisos viejos
        await _db.RunAsync((cn, tx) => cn.ExecuteAsync(
            $"DELETE FROM NOTIFICACION WHERE fecha < now() - interval '{DiasConservar} days';", transaction: tx));

        var filas = await _db.RunAsync((cn, tx) => cn.QueryAsync<AvisoDto>(
            @"SELECT id_notificacion AS Id, tipo AS Tipo, titulo AS Titulo, mensaje AS Mensaje, fecha AS Fecha
              FROM NOTIFICACION WHERE rol_destino = @Rol ORDER BY id_notificacion DESC LIMIT 100;",
            new { Rol = rol }, transaction: tx));
        return filas.ToList();
    }
}
