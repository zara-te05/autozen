using System.Data;
using Autozen.Api.Data;
using Autozen.Api.DTOs;
using Autozen.Api.Models;
using Dapper;

namespace Autozen.Api.Repositories;

public interface IDetalleCotizacionRepository
{
    Task<IEnumerable<DetalleCotizacion>> GetAllAsync();
    Task<DetalleCotizacion?> GetByIdAsync(int id);
    Task<DetalleCotizacion> CreateAsync(CreateDetalleCotizacionDto dto);
    Task<bool> UpdateAsync(int id, CreateDetalleCotizacionDto dto);
    Task<bool> DeleteAsync(int id);
}

public class DetalleCotizacionRepository : IDetalleCotizacionRepository
{
    private readonly DapperContext _context;

    public DetalleCotizacionRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<DetalleCotizacion>> GetAllAsync()
    {
        const string query = "SELECT \"id_detalle_cotizacion\" AS \"IdDetalleCotizacion\", \"cotizacion_id\" AS \"CotizacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"descripcionTrabajo_Pieza\" AS \"DescripcionTrabajoPieza\", \"costoPiezasTomadasAlmacen\" AS \"CostoPiezasTomadasAlmacen\", \"trabajadoresAsignados\" AS \"TrabajadoresAsignados\" FROM DETALLE_COTIZACION;";
        using var connection = _context.CreateConnection();
        return await connection.QueryAsync<DetalleCotizacion>(query);
    }

    public async Task<DetalleCotizacion?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_detalle_cotizacion\" AS \"IdDetalleCotizacion\", \"cotizacion_id\" AS \"CotizacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"descripcionTrabajo_Pieza\" AS \"DescripcionTrabajoPieza\", \"costoPiezasTomadasAlmacen\" AS \"CostoPiezasTomadasAlmacen\", \"trabajadoresAsignados\" AS \"TrabajadoresAsignados\" FROM DETALLE_COTIZACION WHERE \"id_detalle_cotizacion\" = @Id;";
        using var connection = _context.CreateConnection();
        return await connection.QueryFirstOrDefaultAsync<DetalleCotizacion>(query, new { Id = id });
    }

    public async Task<DetalleCotizacion> CreateAsync(CreateDetalleCotizacionDto dto)
    {
        const string query = "INSERT INTO DETALLE_COTIZACION (\"cotizacion_id\", \"trabajador_id\", \"descripcionTrabajo_Pieza\", \"costoPiezasTomadasAlmacen\", \"trabajadoresAsignados\") VALUES (@CotizacionId, @TrabajadorId, @DescripcionTrabajoPieza, @CostoPiezasTomadasAlmacen, @TrabajadoresAsignados) RETURNING \"id_detalle_cotizacion\" AS \"IdDetalleCotizacion\", \"cotizacion_id\" AS \"CotizacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"descripcionTrabajo_Pieza\" AS \"DescripcionTrabajoPieza\", \"costoPiezasTomadasAlmacen\" AS \"CostoPiezasTomadasAlmacen\", \"trabajadoresAsignados\" AS \"TrabajadoresAsignados\";";

        using var connection = _context.CreateConnection();
        return await connection.QuerySingleAsync<DetalleCotizacion>(query, dto);
    }

    public async Task<bool> UpdateAsync(int id, CreateDetalleCotizacionDto dto)
    {
        const string query = "UPDATE DETALLE_COTIZACION SET \"cotizacion_id\" = @CotizacionId, \"trabajador_id\" = @TrabajadorId, \"descripcionTrabajo_Pieza\" = @DescripcionTrabajoPieza, \"costoPiezasTomadasAlmacen\" = @CostoPiezasTomadasAlmacen, \"trabajadoresAsignados\" = @TrabajadoresAsignados WHERE \"id_detalle_cotizacion\" = @Id;";

        using var connection = _context.CreateConnection();
        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await connection.ExecuteAsync(query, parameters);
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM DETALLE_COTIZACION WHERE \"id_detalle_cotizacion\" = @Id;";
        using var connection = _context.CreateConnection();
        var rowsAffected = await connection.ExecuteAsync(query, new { Id = id });
        return rowsAffected > 0;
    }
}
