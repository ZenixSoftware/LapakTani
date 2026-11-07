import 'package:flutter_test/flutter_test.dart';
import 'package:lapaktani_app/features/navigation/role_based_app_shell.dart';
import 'package:lapaktani_app/main.dart';

void main() {
  testWidgets('LapakTani app initialization smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LapakTaniApp());
    expect(find.byType(RoleBasedAppShell), findsOneWidget);
  });
}
