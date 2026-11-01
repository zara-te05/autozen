using System.Data;
using System.Data.Common;
using Dapper;
using Npgsql;

namespace Autozen.Api.Data;

/// <summary>
/// Punto único de acceso a PostgreSQL. Se registra como Scoped (una instancia por petición HTTP)
/// para que los repositorios compartan la transacción activa abierta con <see cref="EnTransaccionAsync{T}"/>.
/// </summary>
public sealed class DapperContext
{
    private readonly string _connectionString;
    private DbConnection? _transactionConnection;
    private DbTransaction? _transaction;

    public DapperContext(IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:DefaultConnection no está configurada. Configúrala con 'dotnet user-secrets' o la variable de entorno ConnectionStrings__DefaultConnection.");
        }
        _connectionString = connectionString;

        DefaultTypeMap.MatchNamesWithUnderscores = true;
    }

    /// <summary>
    /// Crea una conexión nueva e independiente (no participa en la transacción activa).
    /// Para consultas normales usa <see cref="RunAsync{T}"/>.
    /// </summary>
    public IDbConnection CreateConnection() => new NpgsqlConnection(_connectionString);

    /// <summary>
    /// Ejecuta una operación de Dapper. Si hay una transacción activa la usa;
    /// si no, abre y cierra una conexión propia.
    /// </summary>
    public async Task<T> RunAsync<T>(Func<IDbConnection, IDbTransaction?, Task<T>> work)
    {
        if (_transaction is not null)
        {
            return await work(_transactionConnection!, _transaction);
        }

        await using var connection = new NpgsqlConnection(_connectionString);
        return await work(connection, null);
    }

    /// <summary>
    /// Ejecuta <paramref name="work"/> dentro de una transacción. Hace commit si termina bien
    /// y rollback si lanza una excepción. Si ya hay una transacción activa, se une a ella.
    /// </summary>
    public async Task<T> EnTransaccionAsync<T>(Func<Task<T>> work)
    {
        if (_transaction is not null)
        {
            return await work();
        }

        await using var connection = new NpgsqlConnection(_connectionString);
        await connection.OpenAsync();
        await using var transaction = await connection.BeginTransactionAsync();

        _transactionConnection = connection;
        _transaction = transaction;
        try
        {
            var resultado = await work();
            await transaction.CommitAsync();
            return resultado;
        }
        finally
        {
            // Si no hubo commit, DisposeAsync de la transacción hace rollback.
            _transaction = null;
            _transactionConnection = null;
        }
    }
}
