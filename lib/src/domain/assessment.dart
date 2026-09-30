import 'product.dart';

enum NutrientLevel { low, medium, high }

class AssessmentMetric {
  const AssessmentMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.level,
    required this.explanation,
  });

  final String name;
  final num value;
  final String unit;
  final NutrientLevel level;
  final String explanation;
}

class CibusAssessment {
  const CibusAssessment({
    required this.status,
    required this.confidence,
    required this.reasons,
    this.missingData = const [],
    this.warnings = const [],
    this.metrics = const [],
    this.methodologyVersion = methodologyVersion,
  });

  static const methodologyVersion = 'Cibus Food 1.0.0';

  final CibusStatus status;
  final ConfidenceLevel confidence;
  final List<String> reasons;
  final List<String> missingData;
  final List<String> warnings;
  final List<AssessmentMetric> metrics;
  final String methodologyVersion;

  factory CibusAssessment.forProduct(Product product) {
    if (product.kind != ProductKind.food) {
      return const CibusAssessment(
        status: CibusStatus.developing,
        confidence: ConfidenceLevel.low,
        reasons: [
          'La metodología Cibus Food 1.0.0 solo se aplica a alimentos.',
          'Los cosméticos necesitan una metodología independiente todavía no disponible.',
        ],
      );
    }

    final specialCategory = _specialCategory(product.categories);
    if (specialCategory != null) {
      return CibusAssessment(
        status: CibusStatus.insufficient,
        confidence: ConfidenceLevel.low,
        reasons: const [
          'No se asigna un color cuando la categoría necesita reglas específicas.',
        ],
        missingData: [
          'La categoría “$specialCategory” no está cubierta por Cibus Food 1.0.0.',
        ],
      );
    }

    final missing = <String>[];
    final n = product.nutriments;
    if (product.isBeverage == null) {
      missing.add('No se puede determinar si el producto es sólido o una bebida.');
    }
    final expectedBasis = product.isBeverage == true
        ? NutritionBasis.per100ml
        : NutritionBasis.per100g;
    if (product.nutritionBasis != expectedBasis) {
      missing.add(product.isBeverage == true
          ? 'Faltan valores nutricionales confirmados por 100 ml.'
          : 'Faltan valores nutricionales confirmados por 100 g.');
    }
    final required = <String, num?>{
      'energía': n.energyKcal,
      'grasas saturadas': n.saturatedFat,
      'azúcares': n.sugars,
      'sal': n.salt,
    };
    for (final entry in required.entries) {
      if (entry.value == null) missing.add('Falta el dato de ${entry.key}.');
    }

    final warnings = _validate(n);
    if (missing.isNotEmpty || warnings.isNotEmpty) {
      return CibusAssessment(
        status: CibusStatus.insufficient,
        confidence: ConfidenceLevel.low,
        reasons: const [
          'No se ha calculado un color porque la entrada no cumple los requisitos de la metodología.',
          'Un dato ausente nunca se sustituye por cero.',
        ],
        missingData: missing,
        warnings: warnings,
      );
    }

    final beverage = product.isBeverage!;
    final unit = beverage ? 'g/100 ml' : 'g/100 g';
    final metrics = <AssessmentMetric>[
      _metric('Azúcares', n.sugars!, unit, _sugarsLevel(n.sugars!, beverage)),
      _metric(
        'Grasas saturadas',
        n.saturatedFat!,
        unit,
        _saturatedFatLevel(n.saturatedFat!, beverage),
      ),
      _metric('Sal', n.salt!, unit, _saltLevel(n.salt!, beverage)),
      _metric(
        'Densidad energética',
        n.energyKcal!,
        beverage ? 'kcal/100 ml' : 'kcal/100 g',
        _energyLevel(n.energyKcal!),
      ),
    ];
    final highCount = metrics.where((metric) => metric.level == NutrientLevel.high).length;
    final mediumCount = metrics.where((metric) => metric.level == NutrientLevel.medium).length;
    var status = highCount >= 2
        ? CibusStatus.red
        : highCount == 1 || mediumCount >= 3
            ? CibusStatus.orange
            : mediumCount > 0
                ? CibusStatus.yellow
                : CibusStatus.green;

    final favorable = <String>[];
    if (n.fiber != null && n.fiber! >= 6) {
      favorable.add('Fibra: ${_format(n.fiber!)} $unit, contenido alto según el umbral europeo de declaraciones nutricionales.');
    }
    final proteinEnergyShare = n.proteins == null || n.energyKcal! <= 0
        ? null
        : (n.proteins! * 4 / n.energyKcal!) * 100;
    if (proteinEnergyShare != null && proteinEnergyShare >= 20) {
      favorable.add('Proteínas: ${_format(proteinEnergyShare)} % de la energía, contenido alto según el umbral europeo.');
    }
    // Un único descenso como máximo y nunca si existe un factor alto.
    if (favorable.isNotEmpty && highCount == 0 && status == CibusStatus.orange) {
      status = CibusStatus.yellow;
    }

    return CibusAssessment(
      status: status,
      confidence: ConfidenceLevel.high,
      reasons: [
        ...metrics.map((metric) => metric.explanation),
        ...favorable,
        if (favorable.isNotEmpty)
          'Los factores favorables tienen un efecto limitado y no pueden compensar ningún factor alto.',
        'La presencia de aditivos o números E no modifica automáticamente el resultado.',
      ],
      metrics: metrics,
    );
  }

  static AssessmentMetric _metric(
    String name,
    num value,
    String unit,
    NutrientLevel level,
  ) {
    final label = switch (level) {
      NutrientLevel.low => 'bajo',
      NutrientLevel.medium => 'medio',
      NutrientLevel.high => 'alto',
    };
    return AssessmentMetric(
      name: name,
      value: value,
      unit: unit,
      level: level,
      explanation: '$name: ${_format(value)} $unit, nivel $label.',
    );
  }

  static List<String> _validate(Nutriments n) {
    final warnings = <String>[];
    final values = <String, num?>{
      'energía': n.energyKcal,
      'grasas': n.fat,
      'grasas saturadas': n.saturatedFat,
      'hidratos de carbono': n.carbohydrates,
      'azúcares': n.sugars,
      'fibra': n.fiber,
      'proteínas': n.proteins,
      'sal': n.salt,
    };
    for (final entry in values.entries) {
      final value = entry.value;
      if (value != null && (!value.isFinite || value < 0)) {
        warnings.add('El valor de ${entry.key} no es válido (${value.toString()}).');
      }
    }
    if (n.saturatedFat != null && n.fat != null && n.saturatedFat! > n.fat!) {
      warnings.add('Las grasas saturadas superan a las grasas totales.');
    }
    if (n.sugars != null && n.carbohydrates != null && n.sugars! > n.carbohydrates!) {
      warnings.add('Los azúcares superan a los hidratos de carbono.');
    }
    for (final entry in values.entries.where((entry) => entry.key != 'energía')) {
      if (entry.value != null && entry.value! > 100) {
        warnings.add('El valor de ${entry.key} supera 100 g en la base declarada.');
      }
    }
    return warnings;
  }

  static NutrientLevel _sugarsLevel(num value, bool beverage) => _level(
        value,
        beverage ? 2.5 : 5,
        beverage ? 11.25 : 22.5,
      );

  static NutrientLevel _saturatedFatLevel(num value, bool beverage) => _level(
        value,
        beverage ? 0.75 : 1.5,
        beverage ? 2.5 : 5,
      );

  static NutrientLevel _saltLevel(num value, bool beverage) => _level(
        value,
        0.3,
        beverage ? 0.75 : 1.5,
      );

  // Cibus groups the published UK NPM energy point steps at 1005 kJ
  // (240 kcal) and 2680 kJ (640 kcal) into its own low/medium/high bands.
  // The UK model does not define these three Cibus labels.
  static NutrientLevel _energyLevel(num kcal) => _level(kcal, 240, 640);

  static NutrientLevel _level(num value, num lowMaximum, num highBoundary) {
    if (value <= lowMaximum) return NutrientLevel.low;
    if (value > highBoundary) return NutrientLevel.high;
    return NutrientLevel.medium;
  }

  static String? _specialCategory(List<String> categories) {
    const excluded = {
      'alcoholic-beverages': 'bebidas alcohólicas',
      'baby-foods': 'alimentos infantiles',
      'infant-formulas': 'fórmulas infantiles',
      'dietary-supplements': 'complementos alimenticios',
      'meal-replacements': 'sustitutivos de comidas',
    };
    for (final category in categories) {
      final normalized = category.replaceFirst(RegExp(r'^[a-z]{2}:'), '');
      for (final entry in excluded.entries) {
        if (normalized == entry.key || normalized.contains(entry.key)) return entry.value;
      }
    }
    return null;
  }

  static String _format(num value) {
    final decimal = value.toStringAsFixed(1);
    return decimal.endsWith('.0') ? decimal.substring(0, decimal.length - 2) : decimal;
  }
}
