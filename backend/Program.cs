using Autozen.Api.Data;
using Autozen.Api.Repositories;
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

app.UseAuthorization();

app.MapControllers();

app.Run();
