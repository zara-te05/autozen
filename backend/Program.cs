using System.Text;
using Autozen.Api.Data;
using Autozen.Api.Repositories;
using Autozen.Api.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();

// OpenAPI
builder.Services.AddOpenApi();

// Dapper Context
builder.Services.AddSingleton<DapperContext>();

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
builder.Services.AddScoped<LoginService>();
builder.Services.AddScoped<UsuarioService>();
builder.Services.AddScoped<RegisterUserService>();
builder.Services.AddScoped<AuthService>();
builder.Services.AddScoped<UsuarioAdminService>();
builder.Services.AddScoped<ProyectoService>();
builder.Services.AddScoped<CompraService>();
builder.Services.AddScoped<CompraPdfService>();
builder.Services.AddScoped<AlmacenInventarioService>();
builder.Services.AddScoped<HerramientasService>();

// JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Jwt:Key no está configurada en appsettings.json.");
var jwtIssuer = builder.Configuration["Jwt:Issuer"];
var jwtAudience = builder.Configuration["Jwt:Audience"];

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false; // Útil para desarrollo local sin certificados https
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

builder.Services.AddAuthorization();

// CORS (Allow Flutter Web, Desktop & Mobile)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference(); // Interactive API Docs at /scalar/v1
}

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
