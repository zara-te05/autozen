import 'package:flutter_test/flutter_test.dart';
import 'package:autozen/models/compras.dart';
import 'package:autozen/services/compras_store.dart';
import 'package:autozen/services/proyectos_store.dart';
import 'package:autozen/utils/numero_a_letras.dart';

void main() {
  test('Importe con letra como en la orden impresa', () {
    expect(importeConLetra(917.56), 'Novecientos diecisiete pesos 56/100 M.N.');
    expect(importeConLetra(1), 'Un peso 00/100 M.N.');
    expect(importeConLetra(21000), 'Veintiún mil pesos 00/100 M.N.');
    expect(importeConLetra(1000000), 'Un millón de pesos 00/100 M.N.');
    expect(importeConLetra(101.5), 'Ciento un pesos 50/100 M.N.');
  });

  test('Totales de la orden: subtotal, IVA 16 % y total', () {
    final orden = OrdenCompraDoc(
      folio: 'OC16336',
      fecha: DateTime(2026, 10, 30),
      entrega: DateTime(2026, 10, 30),
      partidas: [PartidaOrden(articulo: 'HER-069', nombre: 'Electrodo 6010 de 1/8" Infra', unidad: 'Kilogramo', unidades: 10, precio: 79.10)],
    );
    expect(orden.subtotal, closeTo(791.00, 0.001));
    expect(orden.iva, closeTo(126.56, 0.001));
    expect(orden.total, closeTo(917.56, 0.001));
  });

  test('Solicitud → Compras la aprueba con la orden', () async {
    final compras = ComprasStore.instancia;
    final proyecto = ProyectosStore.instancia.activos.first;

    expect(await compras.solicitar(proyecto: proyecto, descripcion: 'Balatas', cantidad: 2, unidad: 'Juego'), isNull);
    final solicitud = compras.pendientes.firstWhere((s) => s.descripcion == 'Balatas');

    final sinProveedor = OrdenCompraDoc(folio: 'OC1', fecha: DateTime.now(), entrega: DateTime.now(), partidas: [PartidaOrden(nombre: 'Balatas', unidades: 2, precio: 100)]);
    expect(await compras.aprobar(solicitud, sinProveedor), isNotNull, reason: 'Sin proveedor no se aprueba');

    sinProveedor.proveedorId = 1;
    expect(await compras.aprobar(solicitud, sinProveedor), isNull);
    expect(solicitud.estado, EstadoSolicitud.aprobada);
    expect(await compras.eliminar(solicitud), isNotNull, reason: 'Una aprobada no se elimina');
  });
}
