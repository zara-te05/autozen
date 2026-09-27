using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface ISolicitudCompraRepository
{
    Task<IEnumerable<SolicitudCompra>> GetAllAsync();
    Task<SolicitudCompra?> GetByIdAsync(int id);
    Task<SolicitudCompra> CreateAsync(CreateSolicitudCompraDto dto);
    Task<bool> UpdateAsync(int id, CreateSolicitudCompraDto dto);
    Task<bool> DeleteAsync(int id);
}

public class SolicitudCompraRepository : ISolicitudCompraRepository
{
    private readonly DapperContext _context;

    public SolicitudCompraRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<SolicitudCompra>> GetAllAsync()
    {
        const string query = "SELECT \"id_solicitud_compra\" AS \"IdSolicitudCompra\", \"operacion_id\" AS \"OperacionId\", \"usuario_id\" AS \"UsuarioId\", \"proveedor_id\" AS \"ProveedorId\", \"nombrePiezasCotizadas\" AS \"NombrePiezasCotizadas\", \"cantidadPiezasCotizadas\" AS \"CantidadPiezasCotizadas\", \"fechaSolicitud\" AS \"FechaSolicitud\" FROM SOLICITUD_COMPRA;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<SolicitudCompra>(query);
    }

    public async Task<SolicitudCompra?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_solicitud_compra\" AS \"IdSolicitudCompra\", \"operacion_id\" AS \"OperacionId\", \"usuario_id\" AS \"UsuarioId\", \"proveedor_id\" AS \"ProveedorId\", \"nombrePiezasCotizadas\" AS \"NombrePiezasCotizadas\", \"cantidadPiezasCotizadas\" AS \"CantidadPiezasCotizadas\", \"fechaSolicitud\" AS \"FechaSolicitud\" FROM SOLICITUD_COMPRA WHERE \"id_solicitud_compra\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<SolicitudCompra>(query, new { Id = id });
    }

    public async Task<SolicitudCompra> CreateAsync(CreateSolicitudCompraDto dto)
    {
        const string query = "INSERT INTO SOLICITUD_COMPRA (\"operacion_id\", \"usuario_id\", \"proveedor_id\", \"nombrePiezasCotizadas\", \"cantidadPiezasCotizadas\", \"fechaSolicitud\") VALUES (@OperacionId, @UsuarioId, @ProveedorId, @NombrePiezasCotizadas, @CantidadPiezasCotizadas, @FechaSolicitud) RETURNING \"id_solicitud_compra\" AS \"IdSolicitudCompra\", \"operacion_id\" AS \"OperacionId\", \"usuario_id\" AS \"UsuarioId\", \"proveedor_id\" AS \"ProveedorId\", \"nombrePiezasCotizadas\" AS \"NombrePiezasCotizadas\", \"cantidadPiezasCotizadas\" AS \"CantidadPiezasCotizadas\", \"fechaSolicitud\" AS \"FechaSolicitud\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<SolicitudCompra>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateSolicitudCompraDto dto)
    {
        const string query = "UPDATE SOLICITUD_COMPRA SET \"operacion_id\" = @OperacionId, \"usuario_id\" = @UsuarioId, \"proveedor_id\" = @ProveedorId, \"nombrePiezasCotizadas\" = @NombrePiezasCotizadas, \"cantidadPiezasCotizadas\" = @CantidadPiezasCotizadas, \"fechaSolicitud\" = @FechaSolicitud WHERE \"id_solicitud_compra\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM SOLICITUD_COMPRA WHERE \"id_solicitud_compra\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
