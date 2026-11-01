import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autozen/models/proyecto_taller.dart';
import 'package:autozen/services/proyectos_store.dart';
import 'package:autozen/views/proyectos_screen.dart';

void main() {
  Future<void> abrirClientes(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ProyectosScreen(tipo: TipoProyecto.cliente)));
    await tester.pumpAndSettle();
  }

  testWidgets('El bote de basura mueve el proyecto a Proyectos Archivados y se puede restaurar', (tester) async {
    await abrirClientes(tester);
    expect(find.text('Volvo VNL 2019'), findsOneWidget);

    await tester.tap(find.byTooltip('Archivar proyecto').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sí, archivar'));
    await tester.pumpAndSettle();
    expect(find.text('Volvo VNL 2019'), findsNothing);

    await tester.tap(find.text('Proyectos Archivados'));
    await tester.pumpAndSettle();
    expect(find.text('Volvo VNL 2019'), findsOneWidget);

    await tester.tap(find.byTooltip('Restaurar a activos'));
    await tester.pumpAndSettle();
    expect(find.text('Volvo VNL 2019'), findsNothing);
  });

  testWidgets('Crear proyecto empieza en la Evaluación de Daños y queda en el apartado', (tester) async {
    await abrirClientes(tester);

    await tester.tap(find.text('Crear proyecto'));
    await tester.pumpAndSettle();
    expect(find.text('Evaluación de Daños'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Ej. Kenworth T680 2021'), 'International LT 2022');
    await tester.enterText(find.widgetWithText(TextFormField, 'Ej. DUR-4821'), 'abc-123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre o empresa del cliente'), 'Fletes Laguna');
    expect(find.text('Aseguradora *'), findsNothing, reason: 'Un proyecto de cliente no lleva aseguradora');
    final lista = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
    final dias = find.byKey(const Key('campo-dias-estimados'));
    await tester.scrollUntilVisible(dias, 200, scrollable: lista);
    await tester.enterText(dias, '12');
    await tester.pump();
    expect(find.text('ABC-123'), findsOneWidget, reason: 'La placa se convierte a mayúsculas');

    final chip = find.text('Falla en embrague');
    await tester.scrollUntilVisible(chip, 200, scrollable: lista);
    await tester.tap(chip);
    await tester.pump();

    final guardar = find.text('Guardar evaluación y crear proyecto');
    await tester.scrollUntilVisible(guardar, 200, scrollable: lista);
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    // Se abre el detalle del proyecto recién creado, con los datos de la evaluación
    expect(find.text('International LT 2022'), findsOneWidget);
    final creado = ProyectosStore.instancia.listar(TipoProyecto.cliente, archivados: false).first;
    expect(creado.descripcionDanos, contains('Falla en embrague'));
    expect(creado.etapaActual, 1, reason: 'La evaluación cuenta como etapa completada');
    expect(creado.diasTotales, 12, reason: 'Los días estimados se reparten entre las etapas');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('International LT 2022'), findsOneWidget);
  });

  test('repartirDias respeta el total y deja al menos 1 día por etapa', () {
    final etapas = ProyectoTaller.etapasPorDefecto(TipoProyecto.aseguradora);
    for (final total in [5, 7, 13, 30]) {
      final repartidas = ProyectoTaller.repartirDias(etapas, total);
      expect(repartidas.fold<int>(0, (s, e) => s + e.diasEstimados), total);
      expect(repartidas.every((e) => e.diasEstimados >= 1), isTrue);
    }
  });

  test('Proyecto de aseguradora usa la fecha comprometida y avisa si vence', () {
    final hoy = DateTime.now();
    final proyecto = ProyectoTaller(
      id: 'PA-T',
      tipo: TipoProyecto.aseguradora,
      nombreCamion: 'Prueba',
      cliente: '',
      aseguradora: 'Seguros Prueba',
      placa: 'X-1',
      fechaIngreso: hoy.subtract(const Duration(days: 10)),
      fechaEntregaComprometida: hoy.subtract(const Duration(days: 1)),
      etapas: ProyectoTaller.etapasPorDefecto(TipoProyecto.aseguradora),
      etapaActual: 2,
    );
    expect(proyecto.nombreContraparte, 'Seguros Prueba');
    expect(ProyectoTaller.diasEntre(proyecto.fechaEntrega, hoy), 1);
    expect(proyecto.entregaVencida, isTrue);
    proyecto.etapaActual = proyecto.etapas.length;
    expect(proyecto.entregaVencida, isFalse, reason: 'Un proyecto terminado ya no está vencido');
  });
}
