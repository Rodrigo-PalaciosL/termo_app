import 'package:flutter_test/flutter_test.dart';

import 'package:termo_engine/main.dart';

void main() {
  testWidgets('renders the app home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TermoEngineApp());

    expect(find.text('TermoEngine'), findsOneWidget);
    expect(find.text('Motor térmico listo para usar'), findsOneWidget);
  });
}
