namespace Autozen.Api.Services;

/// <summary>
/// Tarea en segundo plano que borra la coordinación operativa del día después de las 7 pm
/// (hora de la Ciudad de México). Revisa cada 10 minutos; el DELETE solo afecta notas vencidas,
/// así que no importa si el contenedor se reinicia o se despierta tarde.
/// </summary>
public class LimpiezaCoordinacionService : BackgroundService
{
    private static readonly TimeSpan Intervalo = TimeSpan.FromMinutes(10);

    private readonly IServiceScopeFactory _scopes;
    private readonly ILogger<LimpiezaCoordinacionService> _logger;

    public LimpiezaCoordinacionService(IServiceScopeFactory scopes, ILogger<LimpiezaCoordinacionService> logger)
    {
        _scopes = scopes;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(Intervalo);
        do
        {
            try
            {
                using var scope = _scopes.CreateScope();
                var borradas = await scope.ServiceProvider.GetRequiredService<TableroService>().BorrarCoordinacionVencidaAsync();
                if (borradas > 0) _logger.LogInformation("Coordinación del día: se borraron {Cantidad} notas (corte de las 7 pm).", borradas);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "No se pudo limpiar la coordinación del día.");
            }
        } while (await timer.WaitForNextTickAsync(stoppingToken));
    }
}
