using Autozen.Api.DTOs;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace Autozen.Api.Services;

public class CompraPdfService
{
    static CompraPdfService()
    {
        // Configuración de licencia comunitaria de QuestPDF
        QuestPDF.Settings.License = LicenseType.Community;
    }

    /// <summary>
    /// Genera en memoria un documento PDF oficial con la orden de compra y todos los datos del proyecto y proveedor.
    /// </summary>
    public byte[] GenerarOrdenCompraPdf(OrdenCompraDetalleResponseDto orden)
    {
        var document = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.Letter);
                page.Margin(1.5f, Unit.Centimetre);
                page.PageColor(Colors.White);
                page.DefaultTextStyle(x => x.FontSize(10).FontColor(Colors.Grey.Darken4));

                // 1. Encabezado
                page.Header().Column(col =>
                {
                    col.Item().Row(row =>
                    {
                        row.RelativeItem().Column(c =>
                        {
                            c.Item().Text("AUTOZEN TALLER AUTOMOTRIZ").Bold().FontSize(18).FontColor(Colors.Blue.Darken3);
                            c.Item().Text("Departamento de Compras y Abastecimiento").FontSize(10).FontColor(Colors.Grey.Darken1);
                        });

                        row.ConstantItem(180).Column(c =>
                        {
                            c.Item().Border(1).BorderColor(Colors.Grey.Lighten1).Padding(8).Column(box =>
                            {
                                box.Item().Text($"ORDEN DE COMPRA").Bold().FontSize(11).FontColor(Colors.Blue.Darken2);
                                box.Item().Text($"Folio: #{orden.IdCompra:D5}").FontSize(11).Bold();
                                box.Item().Text($"Fecha: {DateTime.Now:dd/MM/yyyy}").FontSize(9);
                            });
                        });
                    });

                    col.Item().PaddingTop(10).LineHorizontal(1.5f).LineColor(Colors.Blue.Darken2);
                });

                // 2. Contenido principal
                page.Content().PaddingVertical(15).Column(col =>
                {
                    col.Spacing(12);

                    // Sección: Datos del Proveedor y Tiempos Estimados
                    col.Item().Row(row =>
                    {
                        row.RelativeItem().Border(1).BorderColor(Colors.Grey.Lighten2).Padding(10).Column(prov =>
                        {
                            prov.Item().Text("DATOS DEL PROVEEDOR").Bold().FontSize(10).FontColor(Colors.Blue.Darken3);
                            prov.Item().Text($"Proveedor: {orden.NombreProveedor ?? "No especificado"}").Bold();
                            prov.Item().Text($"Contacto / Teléfono: {orden.ContactoProveedor ?? "N/A"}");
                        });

                        row.ConstantItem(15);

                        row.RelativeItem().Border(1).BorderColor(Colors.Grey.Lighten2).Padding(10).Column(tiempos =>
                        {
                            tiempos.Item().Text("TIEMPOS ESTIMADOS DE ENTREGA").Bold().FontSize(10).FontColor(Colors.Blue.Darken3);
                            tiempos.Item().Text($"Tiempo promedio: {orden.TiempoEntregaPromedioDias ?? 3} días hábiles");
                            tiempos.Item().Text($"Fecha estimada: {orden.FechaEstimadaEntrega:dd/MM/yyyy}").Bold().FontColor(Colors.Green.Darken2);
                        });
                    });

                    // Sección: Datos del Proyecto y Vehículo
                    col.Item().Border(1).BorderColor(Colors.Grey.Lighten2).Padding(10).Column(proy =>
                    {
                        proy.Item().Text("DATOS DEL PROYECTO / VEHÍCULO ASOCIADO").Bold().FontSize(10).FontColor(Colors.Blue.Darken3);
                        proy.Item().Row(r =>
                        {
                            r.RelativeItem().Text($"Proyecto: #{orden.OperacionId}");
                            r.RelativeItem().Text($"Placas: {orden.PlacasCamion}").Bold();
                            r.RelativeItem().Text($"Vehículo: {orden.MarcaModeloCamion ?? "N/A"}");
                            r.RelativeItem().Text($"Cliente: {orden.NombreCliente ?? "N/A"}");
                        });
                        proy.Item().Text($"Solicitado por: {orden.SolicitadoPor ?? "Área de Taller"}").FontSize(9).FontColor(Colors.Grey.Darken1);
                    });

                    // Sección: Tabla de Piezas / Materiales
                    col.Item().PaddingTop(10).Table(tabla =>
                    {
                        tabla.ColumnsDefinition(columns =>
                        {
                            columns.RelativeColumn(4); // Descripción
                            columns.RelativeColumn(1); // Cantidad
                            columns.RelativeColumn(2); // Costo Unitario
                            columns.RelativeColumn(2); // Importe Total
                        });

                        // Encabezados de tabla
                        tabla.Header(header =>
                        {
                            header.Cell().Background(Colors.Blue.Darken3).Padding(6).Text("Descripción de la Pieza / Refacción").Bold().FontColor(Colors.White);
                            header.Cell().Background(Colors.Blue.Darken3).Padding(6).AlignCenter().Text("Cant.").Bold().FontColor(Colors.White);
                            header.Cell().Background(Colors.Blue.Darken3).Padding(6).AlignRight().Text("Costo Unit.").Bold().FontColor(Colors.White);
                            header.Cell().Background(Colors.Blue.Darken3).Padding(6).AlignRight().Text("Total").Bold().FontColor(Colors.White);
                        });

                        // Fila de datos
                        decimal costoUnitario = orden.CantidadPiezas > 0 ? (orden.CostoPiezas / orden.CantidadPiezas) : orden.CostoPiezas;

                        tabla.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(8).Text(orden.NombrePiezas);
                        tabla.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(8).AlignCenter().Text(orden.CantidadPiezas.ToString());
                        tabla.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(8).AlignRight().Text($"${costoUnitario:N2}");
                        tabla.Cell().BorderBottom(1).BorderColor(Colors.Grey.Lighten2).Padding(8).AlignRight().Text($"${orden.CostoPiezas:N2}").Bold();
                    });

                    // Total general
                    col.Item().AlignRight().PaddingTop(5).Row(r =>
                    {
                        r.ConstantItem(150).Border(1).BorderColor(Colors.Grey.Lighten2).Background(Colors.Grey.Lighten4).Padding(8).Row(tot =>
                        {
                            tot.RelativeItem().Text("TOTAL:").Bold().FontSize(12);
                            tot.RelativeItem().AlignRight().Text($"${orden.CostoPiezas:N2}").Bold().FontSize(12).FontColor(Colors.Blue.Darken3);
                        });
                    });

                    // Firmas
                    col.Item().PaddingTop(50).Row(r =>
                    {
                        r.RelativeItem().Column(f =>
                        {
                            f.Item().LineHorizontal(1).LineColor(Colors.Grey.Darken1);
                            f.Item().AlignCenter().Text("Firma Solicitante").FontSize(9);
                        });

                        r.ConstantItem(60);

                        r.RelativeItem().Column(f =>
                        {
                            f.Item().LineHorizontal(1).LineColor(Colors.Grey.Darken1);
                            f.Item().AlignCenter().Text("Autorización Compras / Administración").FontSize(9);
                        });
                    });
                });

                // 3. Pie de página
                page.Footer().AlignCenter().Text(t =>
                {
                    t.Span("Documento oficial generado por AutoZen ERP. ").FontSize(8).FontColor(Colors.Grey.Darken1);
                    t.Span("Página ");
                    t.CurrentPageNumber();
                    t.Span(" de ");
                    t.TotalPages();
                });
            });
        });

        return document.GeneratePdf();
    }
}
