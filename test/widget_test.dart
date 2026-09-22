import 'package:cibus/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la portada y la escala completa', (tester) async {
    await tester.pumpWidget(const CibusApp());

    expect(find.text('Cibus'), findsOneWidget);
    expect(find.text('Escanear código de barras'), findsOneWidget);
    expect(find.text('Excelente'), findsOneWidget);
    expect(find.text('Bueno'), findsOneWidget);
    expect(find.text('Mejorable'), findsOneWidget);
    expect(find.text('Poco recomendable'), findsOneWidget);
    expect(find.text('Datos insuficientes / Análisis en desarrollo'), findsOneWidget);
  });
}
