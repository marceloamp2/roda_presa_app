import 'package:flutter_test/flutter_test.dart';

import 'package:roda_presa_app/main.dart';

void main() {
  testWidgets('opens straight into the public ride feed', (tester) async {
    await tester.pumpWidget(const RodaPresaApp());

    expect(find.text('Próximos roles'), findsOneWidget);
    expect(find.text('Campos do Jordão'), findsWidgets);
    expect(find.text('Novo role'), findsOneWidget);
  });
}
