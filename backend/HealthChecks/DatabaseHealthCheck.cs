using System.Data.Common;
using Autozen.Api.Data;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Autozen.Api.HealthChecks;

/// <summary>
/// Verifica que la base de datos PostgreSQL responda.
/// </summary>
public class DatabaseHealthCheck : IHealthCheck
{
    private readonly DapperContext _context;

    public DatabaseHealthCheck(DapperContext context)
    {
        _context = context;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            using var connection = (DbConnection)_context.CreateConnection();
            await connection.OpenAsync(cancellationToken);

            using var command = connection.CreateCommand();
            command.CommandText = "SELECT 1";
            await command.ExecuteScalarAsync(cancellationToken);

            return HealthCheckResult.Healthy();
        }
        catch (Exception)
        {
            return HealthCheckResult.Unhealthy("No se pudo conectar a la base de datos.");
        }
    }
}
