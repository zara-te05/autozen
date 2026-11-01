namespace Autozen.Api.Errors;

/// <summary>
/// Error esperado por una regla del negocio (stock insuficiente, dato inválido, etc.).
/// El manejador global lo responde como ProblemDetails con su mensaje y código.
/// </summary>
public class ReglaNegocioException(string mensaje, int status = StatusCodes.Status400BadRequest) : Exception(mensaje)
{
    public int Status { get; } = status;
}

public class NoEncontradoException(string mensaje) : ReglaNegocioException(mensaje, StatusCodes.Status404NotFound);

public class ConflictoException(string mensaje) : ReglaNegocioException(mensaje, StatusCodes.Status409Conflict);
