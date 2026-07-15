import 'package:flutter_test/flutter_test.dart';

import 'package:termo_app/main.dart';

void main() {
  testWidgets('renders the app home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TermoApp());

    expect(find.text('TermoApp'), findsOneWidget);
    expect(find.text('Motor térmico listo para usar'), findsOneWidget);
  });
}
