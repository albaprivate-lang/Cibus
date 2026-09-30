import 'package:cibus/src/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra la portada y la escala completa', (tester) async {
    await tester.pumpWidget(const CibusApp());

    expect(find.text('Cibus'), findsOneWidget);
    expect(find.text('Escanear código de barras'), findsOneWidget);
    expect(find.text('Verde · perfil favorable'), findsOneWidget);
    expect(find.text('Amarillo · atención moderada'), findsOneWidget);
    expect(find.text('Naranja · atención elevada'), findsOneWidget);
    expect(find.text('Rojo · atención muy elevada'), findsOneWidget);
    expect(find.text('Datos insuficientes · se explica qué falta'), findsOneWidget);
  });
}
