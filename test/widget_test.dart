import 'package:flutter_test/flutter_test.dart';
import 'package:autozen/main.dart';

void main() {
  testWidgets('AutozenApp smoke test and login screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AutozenApp());
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Verify that the login screen title exists.
    expect(find.text('AUTÖSEN'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
