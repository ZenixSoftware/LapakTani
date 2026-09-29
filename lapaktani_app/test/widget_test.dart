import 'package:flutter_test/flutter_test.dart';
import 'package:lapaktani_app/main.dart';

void main() {
  testWidgets('LapakTani app initialization smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LapakTaniApp());
    expect(find.text('LapakTani Core Initialized'), findsOneWidget);
  });
}
