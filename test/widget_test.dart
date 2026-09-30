import 'package:cibus/src/app.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const scaleLabels = [
    'Verde · perfil favorable',
    'Amarillo · atención moderada',
    'Naranja · atención elevada',
    'Rojo · atención muy elevada',
    'Datos insuficientes · se explica qué falta',
  ];

  // Logical pixels: include a narrow 320 px viewport and enlarged system text.
  for (final size in [const Size(320, 640), const Size(360, 800)]) {
    for (final textScale in [1.0, 2.0]) {
      testWidgets(
        'escala sin overflow a ${size.width} px y texto $textScale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await tester.pumpWidget(const CibusApp());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          for (final label in scaleLabels) {
            final finder = find.text(label);
            expect(finder, findsOneWidget);
            await tester.ensureVisible(finder);
            await tester.pumpAndSettle();

            final paragraph = tester.renderObject<RenderParagraph>(finder);
            expect(paragraph.didExceedMaxLines, isFalse);
            expect(paragraph.text.toPlainText(), label);
            final bounds = tester.getRect(finder);
            expect(bounds.left, greaterThanOrEqualTo(0));
            expect(bounds.right, lessThanOrEqualTo(size.width));
            expect(bounds.top, greaterThanOrEqualTo(0));
            expect(bounds.bottom, lessThanOrEqualTo(size.height));
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

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
