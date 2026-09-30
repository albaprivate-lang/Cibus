import 'package:flutter/material.dart';

import '../data/open_facts_client.dart';
import '../domain/assessment.dart';
import '../domain/product.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required this.barcode, required this.client});
  final String barcode;
  final OpenFactsClient client;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late final Future<ProductLookupResult> _result = widget.client.lookup(widget.barcode);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Resultado')),
        body: FutureBuilder<ProductLookupResult>(
          future: _result,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MessageState(
                icon: Icons.cloud_off_rounded,
                title: 'No se pudo completar la consulta',
                message: 'Ha ocurrido un error inesperado. Inténtalo de nuevo.',
              );
            }
            final result = snapshot.data!;
            if (result.isFailure) {
              return _MessageState(icon: Icons.wifi_off_rounded, title: 'Sin resultados', message: result.errorMessage!);
            }
            if (!result.isFound) {
              return _MessageState(
                icon: Icons.question_mark_rounded,
                title: 'Datos insuficientes',
                message: 'El producto ${widget.barcode} no aparece en Open Food Facts ni en Open Beauty Facts. Cibus no inventará información.',
              );
            }
            return _ProductDetails(product: result.product!);
          },
        ),
      );
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final assessment = CibusAssessment.forProduct(product);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        Text(product.name ?? 'Producto sin nombre', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        if (product.brand != null) ...[const SizedBox(height: 4), Text(product.brand!, style: Theme.of(context).textTheme.titleMedium)],
        const SizedBox(height: 20),
        _Section(
          title: 'Valoración Cibus',
          subtitle: 'Interpretación propia · separada de los datos de origen',
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _StatusPill(
              text: _statusText(assessment.status),
              color: _statusColor(assessment.status),
              icon: _statusIcon(assessment.status),
            ),
            const SizedBox(height: 14),
            Text('Confianza: ${_confidenceText(assessment.confidence)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            Text('¿Por qué?', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...assessment.reasons.map((reason) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(reason)),
                  ]),
                )),
            if (assessment.missingData.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Información que falta', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...assessment.missingData.map((message) => _NoticeRow(icon: Icons.help_outline, text: message)),
            ],
            if (assessment.warnings.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Datos incoherentes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...assessment.warnings.map((message) => _NoticeRow(icon: Icons.warning_amber_rounded, text: message)),
            ],
            const SizedBox(height: 10),
            Text('Método: ${assessment.methodologyVersion}', style: const TextStyle(color: Color(0xFF66736E), fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Datos del producto',
          subtitle: 'Información proporcionada por ${product.sourceName}',
          child: Column(children: [
            _DataRow(label: 'Tipo', value: product.kind == ProductKind.food ? 'Alimento' : 'Cosmético'),
            _DataRow(label: 'Código de barras', value: product.barcode),
            _DataRow(label: product.kind == ProductKind.food ? 'Ingredientes' : 'INCI / ingredientes', value: product.ingredients),
            if (product.kind == ProductKind.food) ..._nutritionRows(product),
            if (product.kind == ProductKind.food) _DataRow(label: 'Aditivos declarados', value: product.additives.isEmpty ? null : product.additives.join(', ')),
            if (product.kind == ProductKind.food) _DataRow(label: 'Base nutricional', value: _basisText(product.nutritionBasis)),
            if (product.servingSize != null) _DataRow(label: 'Porción declarada', value: product.servingSize),
            if (product.lastModified != null) _DataRow(label: 'Datos actualizados', value: product.lastModified!.toIso8601String()),
            if (product.kind == ProductKind.cosmetic) _DataRow(label: 'Información disponible de ingredientes', value: product.ingredientInformation.isEmpty ? null : product.ingredientInformation.join(', ')),
            _DataRow(label: 'Fuente', value: product.sourceName),
          ]),
        ),
        const SizedBox(height: 14),
        const Text('Los campos sin información se muestran como “No disponible”. La información puede ser aportada por la comunidad y debe contrastarse con el envase.', style: TextStyle(color: Color(0xFF66736E), fontSize: 13)),
      ],
    );
  }

  List<Widget> _nutritionRows(Product product) {
    final n = product.nutriments;
    final base = product.nutritionBasis == NutritionBasis.per100ml
        ? '100 ml'
        : '100 g';
    return [
      _DataRow(label: 'Energía', value: _amount(n.energyKcal, 'kcal / $base')),
      _DataRow(label: 'Grasas', value: _amount(n.fat, 'g / $base')),
      _DataRow(label: 'Grasas saturadas', value: _amount(n.saturatedFat, 'g / $base')),
      _DataRow(label: 'Hidratos de carbono', value: _amount(n.carbohydrates, 'g / $base')),
      _DataRow(label: 'Azúcares', value: _amount(n.sugars, 'g / $base')),
      _DataRow(label: 'Fibra', value: _amount(n.fiber, 'g / $base')),
      _DataRow(label: 'Proteínas', value: _amount(n.proteins, 'g / $base')),
      _DataRow(label: 'Sal', value: _amount(n.salt, 'g / $base')),
    ];
  }

  String? _amount(num? value, String unit) => value == null ? null : '${value.toString()} $unit';
  String _statusText(CibusStatus status) => switch (status) {
        CibusStatus.green => 'Verde · perfil favorable',
        CibusStatus.yellow => 'Amarillo · atención moderada',
        CibusStatus.orange => 'Naranja · atención elevada',
        CibusStatus.red => 'Rojo · atención muy elevada',
        CibusStatus.insufficient => 'Datos insuficientes',
        CibusStatus.developing => 'Análisis en desarrollo',
      };
  Color _statusColor(CibusStatus status) => switch (status) {
        CibusStatus.green => const Color(0xFF176B35),
        CibusStatus.yellow => const Color(0xFF7A5B00),
        CibusStatus.orange => const Color(0xFF9A4300),
        CibusStatus.red => const Color(0xFFA51D1D),
        CibusStatus.insufficient || CibusStatus.developing => const Color(0xFF355E4D),
      };
  IconData _statusIcon(CibusStatus status) => switch (status) {
        CibusStatus.green => Icons.check_circle_outline,
        CibusStatus.yellow => Icons.info_outline,
        CibusStatus.orange => Icons.warning_amber_rounded,
        CibusStatus.red => Icons.report_outlined,
        CibusStatus.insufficient => Icons.help_outline,
        CibusStatus.developing => Icons.science_outlined,
      };
  String? _basisText(NutritionBasis basis) => switch (basis) {
        NutritionBasis.per100g => 'Por 100 g',
        NutritionBasis.per100ml => 'Por 100 ml',
        NutritionBasis.perServing => 'Solo por porción (no se usa para valorar)',
        NutritionBasis.unknown => null,
      };
  String _confidenceText(ConfidenceLevel confidence) => switch (confidence) {
        ConfidenceLevel.high => 'Alto',
        ConfidenceLevel.medium => 'Medio',
        ConfidenceLevel.low => 'Bajo',
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.subtitle, required this.child});
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: Color(0xFF66736E), fontSize: 13)),
          const Divider(height: 28),
          child,
        ]),
      ));
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, this.value});
  final String label;
  final String? value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 132, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: Text(value ?? 'No disponible', style: TextStyle(color: value == null ? const Color(0xFF777D79) : null))),
        ]),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color, required this.icon});
  final String text;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99), border: Border.all(color: color)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 7),
          Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 19, color: const Color(0xFF66736E)),
          const SizedBox(width: 9),
          Expanded(child: Text(text)),
        ]),
      );
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: const Color(0xFF66736E)),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
        ]),
      ));
}
