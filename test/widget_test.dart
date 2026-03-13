import 'package:flutter_test/flutter_test.dart';
import 'package:ai_native_editor/main.dart';

void main() {
  testWidgets('App should start without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const AINativeEditorApp());
    expect(find.text('AI Native Freeform Editor'), findsOneWidget);
  });
}
