using Autozen.Api.DTOs;
using Autozen.Api.Repositories;
using Dapper;

namespace Autozen.Api.Data;

/// <summary>
/// Crea el primer usuario Admin cuando la tabla USUARIO no tiene ninguno.
/// Toma los datos de AdminInicial:Username y AdminInicial:Password (user-secrets o variables de entorno).
/// Si ya existe un Admin no hace nada, así que puede quedarse configurado.
/// </summary>
public static class AdminInicial
{
    public static async Task CrearSiNoExisteAsync(IServiceProvider services, IConfiguration configuration, ILogger logger)
    {
        var username = configuration["AdminInicial:Username"];
        var password = configuration["AdminInicial:Password"];

        using var scope = services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<DapperContext>();

        bool hayAdmin = await context.RunAsync((connection, tx) =>
            connection.ExecuteScalarAsync<bool>("SELECT EXISTS (SELECT 1 FROM USUARIO WHERE rol = @Rol);", new { Rol = Roles.Admin }, transaction: tx));
        if (hayAdmin)
            return;

        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
        {
            logger.LogWarning("No hay ningún usuario Admin. Configura AdminInicial:Username y AdminInicial:Password para crearlo al arrancar.");
            return;
        }

        if (password.Length < 8)
            throw new InvalidOperationException("AdminInicial:Password debe tener al menos 8 caracteres.");

        var usuarios = scope.ServiceProvider.GetRequiredService<IUsuarioRepository>();
        await usuarios.CreateAsync(new CreateUsuarioDto
        {
            Nombre = "Administrador",
            Username = username.Trim(),
            Password = BCrypt.Net.BCrypt.HashPassword(password),
            Rol = Roles.Admin
        });

        logger.LogInformation("Usuario Admin inicial '{Username}' creado.", username.Trim());
    }
}
