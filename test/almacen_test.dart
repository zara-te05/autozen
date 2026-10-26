import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:autozen/views/almacen_screen.dart';

void main() {
  testWidgets('AlmacenScreen loads safe number picker and Desglose de inventario tab', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AlmacenScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify tabs with original names and centered Desglose de inventario
    expect(find.text('Alta de Piezas'), findsOneWidget);
    expect(find.text('Desglose de inventario'), findsOneWidget);
    expect(find.text('Vales de Salida'), findsOneWidget);

    // Verify Safe Number Picker controls in Alta de Piezas
    expect(find.text('Cantidad a Ingresar *'), findsOneWidget);
    expect(find.text('Mínimo 1'), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline), findsWidgets);
    expect(find.byIcon(Icons.remove_circle_outline), findsWidgets);

    // Switch to Desglose de inventario tab
    await tester.tap(find.text('Desglose de inventario'));
    await tester.pumpAndSettle();

    // Verify DataGrid elements
    expect(find.text('Código'), findsOneWidget);
    expect(find.text('Pieza / Refacción'), findsOneWidget);
    expect(find.text('Balatas de freno cerámicas'), findsOneWidget);
    expect(find.text('En Stock'), findsWidgets);
  });
}
