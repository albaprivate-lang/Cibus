import 'package:cibus/src/domain/assessment.dart';
import 'package:cibus/src/domain/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = Uri.parse('https://world.openfoodfacts.org');

  test('no inventa una valoración cuando hay pocos datos', () {
    final product = Product(
      barcode: '12345678',
      kind: ProductKind.food,
      sourceName: 'Open Food Facts',
      sourceUrl: source,
    );

    final assessment = CibusAssessment.forProduct(product);

    expect(assessment.status, CibusStatus.insufficient);
    expect(assessment.confidence, ConfidenceLevel.low);
  });

  test('mantiene el análisis en desarrollo incluso con datos completos', () {
    final product = Product(
      barcode: '12345678',
      kind: ProductKind.food,
      sourceName: 'Open Food Facts',
      sourceUrl: source,
      name: 'Producto',
      brand: 'Marca',
      ingredients: 'Agua, avena',
      nutriments: const Nutriments(
        energyKcal: 40,
        fat: 1,
        saturatedFat: 0.2,
        carbohydrates: 6,
        sugars: 2,
        fiber: 1,
        proteins: 1,
        salt: 0.1,
      ),
      additives: const ['E300'],
    );

    final assessment = CibusAssessment.forProduct(product);

    expect(assessment.status, CibusStatus.developing);
    expect(assessment.confidence, ConfidenceLevel.high);
    expect(assessment.reasons.join(' '), contains('no se penaliza automáticamente'));
  });
}
