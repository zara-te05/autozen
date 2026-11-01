using System.Reflection;
using DbUp;
using DbUp.Engine;
using Npgsql;

namespace Autozen.Api.Data;

/// <summary>
/// Aplica al arrancar los scripts de Database/Migrations (embebidos en el ensamblado) que aún no se
/// hayan ejecutado. DbUp registra cada script aplicado en la tabla public.schemaversions.
/// Usa la cadena ConnectionStrings:Migraciones (usuario dueño del esquema), no la de la API.
/// </summary>
public static class MigracionesBaseDeDatos
{
    private const string MarcaPendiente = "REEMPLAZAR_CON_PG_DUMP";
    private const string ScriptBase = "0001_esquema_base.sql";

    public static void Ejecutar(IConfiguration configuration, ILogger logger)
    {
        var connectionString = configuration.GetConnectionString("Migraciones");
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            logger.LogWarning("ConnectionStrings:Migraciones no está configurada; no se aplican migraciones.");
            return;
        }

        var assembly = Assembly.GetExecutingAssembly();
        var recursoBase = assembly.GetManifestResourceNames().Single(n => n.EndsWith(ScriptBase));
        using (var stream = assembly.GetManifestResourceStream(recursoBase)!)
        using (var reader = new StreamReader(stream))
        {
            if (reader.ReadToEnd().Contains(MarcaPendiente))
            {
                logger.LogWarning("{Script} aún no contiene el esquema exportado con pg_dump; no se aplican migraciones.", ScriptBase);
                return;
            }
        }

        // Crea la base (p. ej. autozen_db) si todavía no existe.
        EnsureDatabase.For.PostgresqlDatabase(connectionString);

        MarcarEsquemaBaseSiYaExiste(connectionString, recursoBase, logger);

        var upgrader = DeployChanges.To
            .PostgresqlDatabase(connectionString)
            .WithScriptsEmbeddedInAssembly(assembly, nombre => nombre.Contains(".Database.Migrations."))
            .WithPreprocessor(new LimpiezaPgDump())
            .JournalToPostgresqlTable("public", "schemaversions")
            .WithTransactionPerScript()
            .LogToConsole()
            .Build();

        var resultado = upgrader.PerformUpgrade();
        if (!resultado.Successful)
        {
            throw new InvalidOperationException($"Falló la migración '{resultado.ErrorScript?.Name}'.", resultado.Error);
        }
    }

    /// <summary>
    /// Una base que ya tiene las tablas (la actual, o una restaurada desde respaldo) no debe volver a
    /// ejecutar el esquema base: se registra como aplicado y solo corren las migraciones posteriores.
    /// </summary>
    private static void MarcarEsquemaBaseSiYaExiste(string connectionString, string recursoBase, ILogger logger)
    {
        using var connection = new NpgsqlConnection(connectionString);
        connection.Open();

        using var existe = new NpgsqlCommand(@"
            SELECT
                to_regclass('public.schemaversions') IS NOT NULL AS hay_journal,
                (to_regclass('public.usuario') IS NOT NULL
                 AND to_regclass('public.almacen') IS NOT NULL
                 AND to_regclass('public.operaciones') IS NOT NULL
                 AND to_regclass('public.camion') IS NOT NULL
                 AND to_regclass('public.cliente') IS NOT NULL) AS hay_tablas;", connection);
        using var lector = existe.ExecuteReader();
        lector.Read();
        bool hayJournal = lector.GetBoolean(0);
        bool hayTablas = lector.GetBoolean(1);
        lector.Close();

        if (hayJournal || !hayTablas)
            return;

        using var marcar = new NpgsqlCommand(@"
            CREATE TABLE public.schemaversions (
                schemaversionsid SERIAL PRIMARY KEY,
                scriptname VARCHAR(255) NOT NULL,
                applied TIMESTAMP NOT NULL
            );
            INSERT INTO public.schemaversions (scriptname, applied) VALUES (@Script, now());", connection);
        marcar.Parameters.AddWithValue("Script", recursoBase);
        marcar.ExecuteNonQuery();

        logger.LogInformation("Base de datos existente detectada: {Script} se marcó como aplicado.", ScriptBase);
    }

    /// <summary>
    /// Quita de los scripts lo que solo entiende psql: metacomandos (\restrict, \connect...) y el
    /// search_path vacío que pone pg_dump, que rompería los scripts siguientes en la misma conexión.
    /// </summary>
    private sealed class LimpiezaPgDump : IScriptPreprocessor
    {
        public string Process(string contents)
        {
            var lineas = contents.Split('\n')
                .Where(l => !l.TrimStart().StartsWith('\\'))
                .Where(l => !l.Contains("set_config('search_path', '', false)"));
            return string.Join('\n', lineas);
        }
    }
}
