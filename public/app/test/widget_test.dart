import 'package:exbf_camera/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ex-Boyfriend Camera shell renders', (WidgetTester tester) async {
    await tester.pumpWidget(const ExbfCameraApp());
    await tester.pump();

    expect(find.text('Camera ready'), findsWidgets);
  });
}
