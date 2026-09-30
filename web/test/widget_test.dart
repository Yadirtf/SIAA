import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/app.dart';

void main() {
  testWidgets('SiaaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SiaaApp());
    expect(find.byType(SiaaApp), findsOneWidget);
  });
}
