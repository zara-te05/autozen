using System.Data;
using Dapper;
using Npgsql;

namespace Autozen.Api.Data;

public class DapperContext
{
    private readonly IConfiguration _configuration;
    private readonly string _connectionString;

    public DapperContext(IConfiguration configuration)
    {
        _configuration = configuration;
        _connectionString = _configuration.GetConnectionString("DefaultConnection")
            ?? throw new InvalidOperationException("Connection string 'DefaultConnection' not found in configuration.");

        DefaultTypeMap.MatchNamesWithUnderscores = true;
    }

    public IDbConnection CreateConnection() => new NpgsqlConnection(_connectionString);
}
