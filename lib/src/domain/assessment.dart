import 'product.dart';

class CibusAssessment {
  const CibusAssessment({
    required this.status,
    required this.confidence,
    required this.reasons,
  });

  final CibusStatus status;
  final ConfidenceLevel confidence;
  final List<String> reasons;

  factory CibusAssessment.forProduct(Product product) {
    final confidence = product.dataPoints >= 8
        ? ConfidenceLevel.high
        : product.dataPoints >= 4
            ? ConfidenceLevel.medium
            : ConfidenceLevel.low;

    return CibusAssessment(
      status: product.dataPoints < 2
          ? CibusStatus.insufficient
          : CibusStatus.developing,
      confidence: confidence,
      reasons: [
        if (product.dataPoints < 2)
          'La fuente no aporta información suficiente para realizar un análisis.'
        else
          'Cibus aún no dispone de reglas científicas verificadas para asignar un color.',
        'La presencia de aditivos o números E no se penaliza automáticamente.',
        'La confianza solo refleja cuántos datos están disponibles, no la calidad del producto.',
      ],
    );
  }
}
