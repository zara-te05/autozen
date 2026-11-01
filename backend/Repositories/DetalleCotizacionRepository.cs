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
        return await _context.RunAsync((connection, tx) => connection.QueryAsync<DetalleCotizacion>(query, transaction: tx));
    }

    public async Task<DetalleCotizacion?> GetByIdAsync(int id)
    {
        const string query = "SELECT \"id_detalle_cotizacion\" AS \"IdDetalleCotizacion\", \"cotizacion_id\" AS \"CotizacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"descripcionTrabajo_Pieza\" AS \"DescripcionTrabajoPieza\", \"costoPiezasTomadasAlmacen\" AS \"CostoPiezasTomadasAlmacen\", \"trabajadoresAsignados\" AS \"TrabajadoresAsignados\" FROM DETALLE_COTIZACION WHERE \"id_detalle_cotizacion\" = @Id;";
        return await _context.RunAsync((connection, tx) => connection.QueryFirstOrDefaultAsync<DetalleCotizacion>(query, new { Id = id }, transaction: tx));
    }

    public async Task<DetalleCotizacion> CreateAsync(CreateDetalleCotizacionDto dto)
    {
        const string query = "INSERT INTO DETALLE_COTIZACION (\"cotizacion_id\", \"trabajador_id\", \"descripcionTrabajo_Pieza\", \"costoPiezasTomadasAlmacen\", \"trabajadoresAsignados\") VALUES (@CotizacionId, @TrabajadorId, @DescripcionTrabajoPieza, @CostoPiezasTomadasAlmacen, @TrabajadoresAsignados) RETURNING \"id_detalle_cotizacion\" AS \"IdDetalleCotizacion\", \"cotizacion_id\" AS \"CotizacionId\", \"trabajador_id\" AS \"TrabajadorId\", \"descripcionTrabajo_Pieza\" AS \"DescripcionTrabajoPieza\", \"costoPiezasTomadasAlmacen\" AS \"CostoPiezasTomadasAlmacen\", \"trabajadoresAsignados\" AS \"TrabajadoresAsignados\";";

        return await _context.RunAsync((connection, tx) => connection.QuerySingleAsync<DetalleCotizacion>(query, dto, transaction: tx));
    }

    public async Task<bool> UpdateAsync(int id, CreateDetalleCotizacionDto dto)
    {
        const string query = "UPDATE DETALLE_COTIZACION SET \"cotizacion_id\" = @CotizacionId, \"trabajador_id\" = @TrabajadorId, \"descripcionTrabajo_Pieza\" = @DescripcionTrabajoPieza, \"costoPiezasTomadasAlmacen\" = @CostoPiezasTomadasAlmacen, \"trabajadoresAsignados\" = @TrabajadoresAsignados WHERE \"id_detalle_cotizacion\" = @Id;";

        var parameters = new DynamicParameters(dto);
        parameters.Add("Id", id);
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, parameters, transaction: tx));
        return rowsAffected > 0;
    }

    public async Task<bool> DeleteAsync(int id)
    {
        const string query = "DELETE FROM DETALLE_COTIZACION WHERE \"id_detalle_cotizacion\" = @Id;";
        var rowsAffected = await _context.RunAsync((connection, tx) => connection.ExecuteAsync(query, new { Id = id }, transaction: tx));
        return rowsAffected > 0;
    }
}
