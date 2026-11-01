import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autozen/models/almacen_inventario.dart';
import 'package:autozen/services/almacen_store.dart';
import 'package:autozen/services/proyectos_store.dart';
import 'package:autozen/views/almacen_screen.dart';

void main() {
  final almacen = AlmacenStore.instancia;

  testWidgets('Almacén muestra sus pestañas y el desglose sin columna de ubicación', (tester) async {
    tester.view.physicalSize = const Size(2400, 1800);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AlmacenScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Alta de Piezas'), findsOneWidget);
    expect(find.text('Desglose de inventario'), findsOneWidget);
    expect(find.text('Vales de Material'), findsOneWidget);
    expect(find.text('Herramientas (deben volver)'), findsOneWidget);

    await tester.tap(find.text('Desglose de inventario'));
    await tester.pumpAndSettle();
    expect(find.text('Balatas de freno cerámicas'), findsOneWidget);
    expect(find.text('Ubicación'), findsNothing);
    expect(find.text('12.5 kg'), findsOneWidget, reason: 'Los artículos por kilo admiten decimales');
  });

  test('Categorías: no se elimina una categoría en uso y renombrar actualiza los artículos', () async {
    expect(await almacen.eliminarCategoria('Frenos'), isNotNull);
    expect(await almacen.agregarCategoria('Pintura'), isNull);
    expect(await almacen.agregarCategoria('pintura'), isNotNull, reason: 'No se permiten duplicados');
    expect(await almacen.renombrarCategoria('Frenos', 'Sistema de frenos'), isNull);
    expect(almacen.articulos.where((a) => a.categoria == 'Sistema de frenos'), isNotEmpty);
    expect(await almacen.eliminarCategoria('Pintura'), isNull);
  });

  test('Vale de material descuenta existencia y suma al dinero invertido del proyecto', () async {
    final proyecto = ProyectosStore.instancia.activos.first;
    final aceite = almacen.articulos.firstWhere((a) => a.unidad == UnidadMedida.litro);
    final antes = aceite.existencia;
    final invertidoAntes = almacen.totalInvertido(proyecto.id);

    expect(await almacen.registrarValeMaterial(proyectoId: proyecto.id, proyectoNombre: proyecto.nombreCamion, articulo: aceite, cantidad: 2.5, entregadoA: ''),
      isNull,
    );
    expect(aceite.existencia, antes - 2.5);
    expect(almacen.totalInvertido(proyecto.id), invertidoAntes + 2.5 * aceite.costoUnitario);

    expect(await almacen.registrarValeMaterial(proyectoId: proyecto.id, proyectoNombre: '', articulo: aceite, cantidad: 9999, entregadoA: ''),
      isNotNull,
      reason: 'No se puede sacar más de lo que hay',
    );

    await almacen.cancelarValeMaterial(almacen.valesMaterialDe(proyecto.id).first);
    expect(aceite.existencia, antes);
  });

  test('Herramienta prestada debe volver: sale del almacén y regresa con la devolución', () async {
    final proyecto = ProyectosStore.instancia.activos.first;
    final martillo = almacen.articulos.firstWhere((a) => a.tipo == TipoArticulo.herramienta);
    final antes = martillo.existencia;

    expect(await almacen.prestarHerramienta(proyectoId: proyecto.id, proyectoNombre: '', articulo: martillo, cantidad: 1.5, entregadoA: 'Juan'), isNotNull,
        reason: 'Las piezas no aceptan decimales');
    expect(await almacen.prestarHerramienta(proyectoId: proyecto.id, proyectoNombre: '', articulo: martillo, cantidad: 1, entregadoA: 'Juan'), isNull);
    expect(martillo.existencia, antes - 1);
    expect(await almacen.eliminarArticulo(martillo), isNotNull, reason: 'No se borra con préstamos abiertos');

    await almacen.registrarDevolucion(almacen.herramientasDe(proyecto.id).first, 'Buen estado');
    expect(martillo.existencia, antes);
  });
}
