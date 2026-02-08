import 'package:flutter_test/flutter_test.dart';
import 'package:termo/main.dart';

void main() {
  testWidgets('TermoApp builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const TermoApp());

    // Verify app title is displayed
    expect(find.text('Termo'), findsOneWidget);
  });
}
