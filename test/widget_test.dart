import 'package:flutter_test/flutter_test.dart';
import 'package:revive/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const ReviveApp());
    expect(find.text('REVIVE'), findsOneWidget);
  });
}
