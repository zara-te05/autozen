import 'package:flutter/material.dart';
import '../models/compras.dart';
import '../utils/empresa.dart';
import '../utils/formato_fecha.dart';

/// Orden de compra con el mismo formato que la hoja impresa.
/// Se dibuja a tamaño carta (ancho fijo) y se escala completa al espacio disponible.
class HojaOrdenCompra extends StatelessWidget {
  final OrdenCompraDoc orden;

  const HojaOrdenCompra({super.key, required this.orden});

  static const double _ancho = 816; // carta a 96 dpi
  static const TextStyle _normal = TextStyle(fontSize: 11, color: Colors.black);
  static const TextStyle _chica = TextStyle(fontSize: 9, color: Colors.black);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: Container(
        width: _ancho,
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black26),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: Text('Orden de compra', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black))),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Empresa.nombre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                      Text(Empresa.direccion, style: _chica),
                      Text(Empresa.ciudad, style: _chica),
                      Text('RFC: ${Empresa.rfc}', style: _chica),
                    ],
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: Table(
                    border: TableBorder.all(color: Colors.black),
                    children: [
                      TableRow(children: [_encabezado('Fecha'), _encabezado('Folio')]),
                      TableRow(children: [_celda(formatearFecha(orden.fecha), centrar: true), _celda(orden.folio, centrar: true)]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _recuadro('Proveedor', [orden.proveedorNombre, orden.proveedorDireccion])),
                const SizedBox(width: 12),
                Expanded(child: _recuadro('Consignatario', [orden.consignatario])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _bloque('Entrega', formatearFecha(orden.entrega)),
                const SizedBox(width: 8),
                _bloque('Condiciones', orden.condiciones),
                const SizedBox(width: 8),
                _bloque('Vía de embarque', orden.viaEmbarque),
              ],
            ),
            const SizedBox(height: 10),
            Table(
              columnWidths: const {
                0: FixedColumnWidth(90),
                1: FlexColumnWidth(),
                2: FixedColumnWidth(80),
                3: FixedColumnWidth(70),
                4: FixedColumnWidth(80),
                5: FixedColumnWidth(70),
                6: FixedColumnWidth(90),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Colors.black),
                  children: [
                    for (final t in ['Artículo', 'Nombre', 'U.med.', 'Unidades', 'Precio', 'Descto.', 'Importe']) _encabezado(t, fondo: false),
                  ],
                ),
                for (final p in orden.partidas)
                  TableRow(children: [
                    _celda(p.articulo),
                    _celda(p.nombre.toUpperCase()),
                    _celda(p.unidad),
                    _celda(_numero(p.unidades), derecha: true),
                    _celda(p.precio.toStringAsFixed(2), derecha: true),
                    _celda(p.descuento == 0 ? '' : p.descuento.toStringAsFixed(2), derecha: true),
                    _celda(_dinero(p.importe), derecha: true),
                  ]),
              ],
            ),
            // Espacio en blanco del cuerpo de la hoja
            SizedBox(height: (260 - orden.partidas.length * 18).clamp(40, 260).toDouble()),
            if (orden.observaciones.trim().isNotEmpty) ...[
              Text('Observaciones: ${orden.observaciones}', style: _normal),
              const SizedBox(height: 10),
            ],
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.black)),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text('(${orden.totalConLetra})', style: _normal),
                      ),
                    ),
                    Container(
                      width: 170,
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.black))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Subtotal', style: _normal),
                          Text(orden.tasaIva == 0 ? 'IVA (exento)' : 'IVA ${(orden.tasaIva * 100).toStringAsFixed(0)}%', style: _normal),
                          const SizedBox(height: 30),
                          const Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Container(
                      width: 110,
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.black))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(_dinero(orden.subtotal), style: _normal),
                          Text(_dinero(orden.iva), style: _normal),
                          const SizedBox(height: 30),
                          Text(_dinero(orden.total), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _numero(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

  static String _dinero(double v) => formatearDinero(v).replaceFirst('\$ ', '');

  static Widget _encabezado(String texto, {bool fondo = true}) => Container(
        color: fondo ? Colors.black : null,
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      );

  static Widget _celda(String texto, {bool derecha = false, bool centrar = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        child: Text(
          texto,
          style: _normal,
          textAlign: derecha ? TextAlign.right : (centrar ? TextAlign.center : TextAlign.left),
        ),
      );

  static Widget _recuadro(String titulo, List<String> lineas) => Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.2)),
        constraints: const BoxConstraints(minHeight: 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _encabezado(titulo),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(lineas.where((l) => l.trim().isNotEmpty).join('\n'), style: _normal),
            ),
          ],
        ),
      );

  static Widget _bloque(String titulo, String valor) => SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_encabezado(titulo), _celda(valor, centrar: true)],
        ),
      );
}
