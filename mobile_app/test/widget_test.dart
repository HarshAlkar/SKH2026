import 'package:flutter_test/flutter_test.dart';
import 'package:hs053/app.dart';

void main() {
  testWidgets('VitalReachApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VitalReachApp());
    expect(find.byType(VitalReachApp), findsOneWidget);
  });
}
