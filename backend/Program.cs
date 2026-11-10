using System.Text;
using System.Threading.RateLimiting;
using Autozen.Api;
using Autozen.Api.Data;
using Autozen.Api.Errors;
using Autozen.Api.HealthChecks;
using Autozen.Api.Repositories;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;

// Permite guardar DateTime en UTC en columnas "timestamp" (sin zona), como hace parte del código existente
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();

// OpenAPI
builder.Services.AddOpenApi();

// Errores: todas las respuestas de error usan el formato ProblemDetails (RFC 9457)
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

// Dapper Context
builder.Services.AddScoped<DapperContext>();

// Repositories
builder.Services.AddScoped<IUsuarioRepository, UsuarioRepository>();
builder.Services.AddScoped<ITrabajadorRepository, TrabajadorRepository>();
builder.Services.AddScoped<IClienteRepository, ClienteRepository>();
builder.Services.AddScoped<ICamionRepository, CamionRepository>();
builder.Services.AddScoped<IProveedorRepository, ProveedorRepository>();
builder.Services.AddScoped<IAlmacenRepository, AlmacenRepository>();
builder.Services.AddScoped<IOperacionRepository, OperacionRepository>();
builder.Services.AddScoped<ICotizacionRepository, CotizacionRepository>();
builder.Services.AddScoped<IDetalleCotizacionRepository, DetalleCotizacionRepository>();
builder.Services.AddScoped<ISolicitudAlmacenRepository, SolicitudAlmacenRepository>();
builder.Services.AddScoped<IEquipoAlmacenRepository, EquipoAlmacenRepository>();
builder.Services.AddScoped<ISolicitudCompraRepository, SolicitudCompraRepository>();
builder.Services.AddScoped<ICompraRepository, CompraRepository>();
builder.Services.AddScoped<IDevolucionProveedorRepository, DevolucionProveedorRepository>();
builder.Services.AddScoped<IMovimientoAlmacenRepository, MovimientoAlmacenRepository>();
builder.Services.AddScoped<IFacturaRepository, FacturaRepository>();
builder.Services.AddScoped<IValeSalidaRepository, ValeSalidaRepository>();

// Services
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<UsuarioAdminService>();
builder.Services.AddScoped<CompraService>();
builder.Services.AddScoped<CompraPdfService>();
builder.Services.AddScoped<HerramientasService>();
builder.Services.AddScoped<ProyectosTallerService>();
builder.Services.AddScoped<AlmacenService>();
builder.Services.AddScoped<DepartamentoService>();
builder.Services.AddScoped<NotificacionService>();
builder.Services.AddScoped<SolicitudesCompraService>();
builder.Services.AddScoped<TableroService>();
builder.Services.AddHostedService<LimpiezaCoordinacionService>();

// JWT Authentication
// Los secretos vienen de user-secrets (desarrollo) o variables de entorno (producción), no de appsettings.json
var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey) || Encoding.UTF8.GetByteCount(jwtKey) < 32)
{
    throw new InvalidOperationException(
        "Jwt:Key no está configurada o tiene menos de 32 bytes. Configúrala con 'dotnet user-secrets' o la variable de entorno Jwt__Key.");
}
var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtIssuer,
        ValidAudience = jwtAudience,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ClockSkew = TimeSpan.Zero
    };
});

// Todo endpoint requiere usuario autenticado salvo los marcados con [AllowAnonymous]
builder.Services.AddAuthorization(options =>
{
    options.FallbackPolicy = new AuthorizationPolicyBuilder()
        .RequireAuthenticatedUser()
        .Build();

    // Pueden dar de alta usuarios el Admin y los jefes de departamento
    options.AddPolicy(Politicas.AltaUsuarios, policy =>
        policy.RequireRole(Roles.Admin, Roles.ProyectoLider, Roles.ComprasAdmin, Roles.AlmacenAdmin, Roles.EvaluacionAdmin));
});

// Rate limiting: máximo 5 intentos de login por minuto por IP
builder.Services.AddRateLimiter(options =>
{
    options.AddPolicy(Politicas.Login, httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: httpContext.Connection.RemoteIpAddress?.ToString() ?? "desconocida",
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0
            }));

    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.OnRejected = async (context, cancellationToken) =>
    {
        if (context.Lease.TryGetMetadata(MetadataName.RetryAfter, out var retryAfter))
        {
            context.HttpContext.Response.Headers.RetryAfter = ((int)retryAfter.TotalSeconds).ToString();
        }

        var problemDetails = context.HttpContext.RequestServices.GetRequiredService<IProblemDetailsService>();
        await problemDetails.WriteAsync(new ProblemDetailsContext
        {
            HttpContext = context.HttpContext,
            ProblemDetails =
            {
                Status = StatusCodes.Status429TooManyRequests,
                Title = "Demasiados intentos",
                Detail = "Has superado el número de intentos de inicio de sesión. Intenta de nuevo en un minuto."
            }
        });
    };
});

// Health checks
builder.Services.AddHealthChecks()
    .AddCheck<DatabaseHealthCheck>("database");

// CORS: solo orígenes permitidos (las apps nativas Android/Windows no usan CORS)
var allowedOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];

builder.Services.AddCors(options =>
{
    options.AddPolicy("Frontend", policy =>
    {
        if (builder.Environment.IsDevelopment())
        {
            // En desarrollo se permite cualquier puerto de localhost (Flutter web, Scalar, etc.)
            policy.SetIsOriginAllowed(origin => new Uri(origin).IsLoopback);
        }
        else
        {
            policy.WithOrigins(allowedOrigins);
        }

        policy.AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Migraciones de base de datos (DbUp) antes de atender peticiones
MigracionesBaseDeDatos.Ejecutar(app.Configuration, app.Logger);
await AdminInicial.CrearSiNoExisteAsync(app.Services, app.Configuration, app.Logger);

app.UseExceptionHandler();
app.UseStatusCodePages();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi().AllowAnonymous();
    app.MapScalarApiReference().AllowAnonymous(); // Interactive API Docs at /scalar/v1
}
else
{
    app.UseHsts();
    app.UseHttpsRedirection();
}

app.UseCors("Frontend");

app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHealthChecks("/health").AllowAnonymous();

app.Run();
