using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Npgsql;

namespace Autozen.Api.Errors;

/// <summary>
/// Captura cualquier excepción no controlada, la registra en el log y responde
/// con un ProblemDetails genérico para no exponer detalles internos al cliente.
/// </summary>
public class GlobalExceptionHandler : IExceptionHandler
{
    private readonly IProblemDetailsService _problemDetailsService;
    private readonly ILogger<GlobalExceptionHandler> _logger;

    public GlobalExceptionHandler(IProblemDetailsService problemDetailsService, ILogger<GlobalExceptionHandler> logger)
    {
        _problemDetailsService = problemDetailsService;
        _logger = logger;
    }

    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        // Reglas del negocio: el mensaje está pensado para mostrarse al usuario
        if (exception is ReglaNegocioException regla)
        {
            httpContext.Response.StatusCode = regla.Status;
            return await _problemDetailsService.TryWriteAsync(new ProblemDetailsContext
            {
                HttpContext = httpContext,
                Exception = exception,
                ProblemDetails = new ProblemDetails
                {
                    Status = regla.Status,
                    Title = regla.Status switch
                    {
                        StatusCodes.Status404NotFound => "No encontrado",
                        StatusCodes.Status409Conflict => "Conflicto",
                        _ => "Solicitud no válida"
                    },
                    Detail = regla.Message
                }
            });
        }

        // Datos rechazados por las reglas de la base: es un error del cliente, no del servidor
        if (exception is PostgresException pg && TraducirErrorDeDatos(pg, httpContext.Request.Method) is { } errorDatos)
        {
            _logger.LogWarning("Datos rechazados por la base ({SqlState}, {Constraint}) en {Method} {Path}",
                pg.SqlState, pg.ConstraintName, httpContext.Request.Method, httpContext.Request.Path);

            httpContext.Response.StatusCode = errorDatos.Status;
            return await _problemDetailsService.TryWriteAsync(new ProblemDetailsContext
            {
                HttpContext = httpContext,
                Exception = exception,
                ProblemDetails = new ProblemDetails
                {
                    Status = errorDatos.Status,
                    Title = errorDatos.Titulo,
                    Detail = errorDatos.Detalle
                }
            });
        }

        _logger.LogError(exception, "Error no controlado en {Method} {Path}", httpContext.Request.Method, httpContext.Request.Path);

        httpContext.Response.StatusCode = StatusCodes.Status500InternalServerError;

        return await _problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            Exception = exception,
            ProblemDetails = new ProblemDetails
            {
                Status = StatusCodes.Status500InternalServerError,
                Title = "Error interno del servidor",
                Detail = "Ocurrió un error inesperado. Si persiste, reporta el traceId al administrador."
            }
        });
    }

    private static (int Status, string Titulo, string Detalle)? TraducirErrorDeDatos(PostgresException pg, string metodo) => pg.SqlState switch
    {
        PostgresErrorCodes.CheckViolation =>
            (StatusCodes.Status400BadRequest, "Valor no permitido", "Uno de los valores enviados no es válido (por ejemplo, un número negativo o un estado no permitido)."),
        PostgresErrorCodes.NotNullViolation =>
            (StatusCodes.Status400BadRequest, "Falta un dato obligatorio", $"El campo '{pg.ColumnName}' es obligatorio."),
        PostgresErrorCodes.ForeignKeyViolation when HttpMethods.IsDelete(metodo) =>
            (StatusCodes.Status409Conflict, "Registro en uso", "No se puede eliminar o modificar porque otros registros dependen de él."),
        PostgresErrorCodes.ForeignKeyViolation =>
            (StatusCodes.Status400BadRequest, "Registro relacionado inexistente", "Uno de los IDs enviados no corresponde a un registro existente."),
        PostgresErrorCodes.UniqueViolation =>
            (StatusCodes.Status409Conflict, "Registro duplicado", "Ya existe un registro con esos datos."),
        _ => null
    };
}
