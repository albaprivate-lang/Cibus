import 'package:cibus/src/domain/assessment.dart';
import 'package:cibus/src/domain/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = Uri.parse('https://world.openfoodfacts.org');

  Product food({
    Nutriments nutriments = const Nutriments(
      energyKcal: 100,
      fat: 2,
      saturatedFat: 1,
      carbohydrates: 10,
      sugars: 4,
      salt: 0.2,
    ),
    bool isBeverage = false,
    NutritionBasis? basis,
    List<String> categories = const ['en:foods'],
  }) =>
      Product(
        barcode: '12345678',
        kind: ProductKind.food,
        sourceName: 'Open Food Facts',
        sourceUrl: source,
        name: 'Producto',
        nutriments: nutriments,
        isBeverage: isBeverage,
        nutritionBasis: basis ??
            (isBeverage ? NutritionBasis.per100ml : NutritionBasis.per100g),
        categories: categories,
      );

  test('asigna verde cuando todos los factores son bajos', () {
    final assessment = CibusAssessment.forProduct(food());
    expect(assessment.status, CibusStatus.green);
    expect(assessment.confidence, ConfidenceLevel.high);
    expect(assessment.metrics, hasLength(4));
  });

  test('asigna amarillo con un factor medio', () {
    final assessment = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 100,
        saturatedFat: 1,
        sugars: 6,
        salt: 0.2,
      ),
    ));
    expect(assessment.status, CibusStatus.yellow);
  });

  test('asigna naranja con un factor alto', () {
    final assessment = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 100,
        saturatedFat: 1,
        sugars: 23,
        salt: 0.2,
      ),
    ));
    expect(assessment.status, CibusStatus.orange);
  });

  test('asigna rojo con dos factores altos', () {
    final assessment = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 700,
        saturatedFat: 1,
        sugars: 23,
        salt: 0.2,
      ),
    ));
    expect(assessment.status, CibusStatus.red);
  });

  test('respeta los límites oficiales bajo y alto', () {
    final lowBoundary = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 100,
        saturatedFat: 1.5,
        sugars: 5,
        salt: 0.3,
      ),
    ));
    final highBoundary = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 100,
        saturatedFat: 5,
        sugars: 22.5,
        salt: 1.5,
      ),
    ));
    expect(lowBoundary.status, CibusStatus.green);
    expect(
      highBoundary.metrics
          .where((metric) => metric.name != 'Densidad energética')
          .every((metric) => metric.level == NutrientLevel.medium),
      isTrue,
    );
  });

  test('aplica los cortes energéticos propios sin atribuirles niveles UK', () {
    CibusAssessment assessmentAt(num energy) =>
        CibusAssessment.forProduct(food(
          nutriments: Nutriments(
            energyKcal: energy,
            saturatedFat: 1,
            sugars: 4,
            salt: 0.2,
          ),
        ));

    NutrientLevel energyLevel(num energy) => assessmentAt(energy)
        .metrics
        .singleWhere((metric) => metric.name == 'Densidad energética')
        .level;

    expect(energyLevel(240), NutrientLevel.low);
    expect(energyLevel(240.01), NutrientLevel.medium);
    expect(energyLevel(640), NutrientLevel.medium);
    expect(energyLevel(640.01), NutrientLevel.high);
  });

  test('aplica límites de bebidas por 100 ml', () {
    const nutrients = Nutriments(
      energyKcal: 20,
      saturatedFat: 0,
      sugars: 3,
      salt: 0,
    );
    expect(
      CibusAssessment.forProduct(food(nutriments: nutrients)).status,
      CibusStatus.green,
    );
    expect(
      CibusAssessment.forProduct(food(
        nutriments: nutrients,
        isBeverage: true,
      )).status,
      CibusStatus.yellow,
    );
  });

  test('respeta límites inclusivos de azúcares, saturadas y sal en bebidas', () {
    CibusAssessment beverageWith({
      required num sugars,
      required num saturatedFat,
      required num salt,
    }) =>
        CibusAssessment.forProduct(food(
          isBeverage: true,
          nutriments: Nutriments(
            energyKcal: 20,
            saturatedFat: saturatedFat,
            sugars: sugars,
            salt: salt,
          ),
        ));

    final lowLimits = beverageWith(
      sugars: 2.5,
      saturatedFat: 0.75,
      salt: 0.3,
    );
    final highLimits = beverageWith(
      sugars: 11.25,
      saturatedFat: 2.5,
      salt: 0.75,
    );
    final aboveHigh = beverageWith(
      sugars: 11.26,
      saturatedFat: 2.51,
      salt: 0.76,
    );

    expect(lowLimits.status, CibusStatus.green);
    expect(
      highLimits.metrics
          .where((metric) => metric.name != 'Densidad energética')
          .every((metric) => metric.level == NutrientLevel.medium),
      isTrue,
    );
    expect(aboveHigh.status, CibusStatus.red);
  });

  test('explica exactamente los datos ausentes', () {
    final assessment = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(energyKcal: 20),
      basis: NutritionBasis.unknown,
    ));
    expect(assessment.status, CibusStatus.insufficient);
    expect(assessment.missingData, contains('Falta el dato de azúcares.'));
    expect(assessment.metrics, isEmpty);
    expect(
      assessment.missingData,
      contains('Faltan valores nutricionales confirmados por 100 g.'),
    );
  });

  test('no valora una base por porción ni un tipo físico desconocido', () {
    final product = Product(
      barcode: '12345678',
      kind: ProductKind.food,
      sourceName: 'Open Food Facts',
      sourceUrl: source,
      nutritionBasis: NutritionBasis.perServing,
      nutriments: const Nutriments(
        energyKcal: 100,
        saturatedFat: 1,
        sugars: 4,
        salt: 0.2,
      ),
    );
    final assessment = CibusAssessment.forProduct(product);
    expect(assessment.status, CibusStatus.insufficient);
    expect(assessment.metrics, isEmpty);
    expect(
      assessment.missingData,
      contains('No se puede determinar si el producto es sólido o una bebida.'),
    );
  });

  test('rechaza valores incoherentes', () {
    final assessment = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 100,
        fat: 2,
        saturatedFat: 3,
        carbohydrates: 5,
        sugars: 7,
        salt: -1,
      ),
    ));
    expect(assessment.status, CibusStatus.insufficient);
    expect(assessment.warnings, hasLength(3));
  });

  test('la fibra y proteína no compensan un factor alto', () {
    final assessment = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 300,
        saturatedFat: 1,
        sugars: 23,
        salt: 0.2,
        fiber: 8,
        proteins: 20,
      ),
    ));
    expect(assessment.status, CibusStatus.orange);
    expect(assessment.reasons.join(' '), contains('efecto limitado'));
  });

  test('un factor favorable reduce como máximo un naranja sin factores altos', () {
    final withoutFiber = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 300,
        saturatedFat: 2,
        sugars: 6,
        salt: 0.2,
      ),
    ));
    final withFiber = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 300,
        saturatedFat: 2,
        sugars: 6,
        salt: 0.2,
        fiber: 6,
      ),
    ));
    expect(withoutFiber.status, CibusStatus.orange);
    expect(withFiber.status, CibusStatus.yellow);
  });

  test('fibra y proteína juntas tampoco mejoran más de un nivel', () {
    final assessment = CibusAssessment.forProduct(food(
      nutriments: const Nutriments(
        energyKcal: 300,
        saturatedFat: 2,
        sugars: 6,
        salt: 0.2,
        fiber: 8,
        proteins: 20,
      ),
    ));
    expect(assessment.status, CibusStatus.yellow);
  });

  test('excluye categorías especiales', () {
    final assessment = CibusAssessment.forProduct(food(
      categories: const ['en:alcoholic-beverages'],
    ));
    expect(assessment.status, CibusStatus.insufficient);
    expect(assessment.missingData.single, contains('bebidas alcohólicas'));
  });

  test('mantiene cosméticos fuera de la valoración alimentaria', () {
    final product = Product(
      barcode: '12345678',
      kind: ProductKind.cosmetic,
      sourceName: 'Open Beauty Facts',
      sourceUrl: source,
    );
    expect(
      CibusAssessment.forProduct(product).status,
      CibusStatus.developing,
    );
  });
}
