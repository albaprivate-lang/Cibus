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
            _StatusPill(text: _statusText(assessment.status)),
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
            if (product.kind == ProductKind.food) ..._nutritionRows(product.nutriments),
            if (product.kind == ProductKind.food) _DataRow(label: 'Aditivos declarados', value: product.additives.isEmpty ? null : product.additives.join(', ')),
            if (product.kind == ProductKind.cosmetic) _DataRow(label: 'Información disponible de ingredientes', value: product.ingredientInformation.isEmpty ? null : product.ingredientInformation.join(', ')),
            _DataRow(label: 'Fuente', value: product.sourceName),
          ]),
        ),
        const SizedBox(height: 14),
        const Text('Los campos sin información se muestran como “No disponible”. La información puede ser aportada por la comunidad y debe contrastarse con el envase.', style: TextStyle(color: Color(0xFF66736E), fontSize: 13)),
      ],
    );
  }

  List<Widget> _nutritionRows(Nutriments n) => [
        _DataRow(label: 'Energía', value: _amount(n.energyKcal, 'kcal / 100 g')),
        _DataRow(label: 'Grasas', value: _amount(n.fat, 'g / 100 g')),
        _DataRow(label: 'Grasas saturadas', value: _amount(n.saturatedFat, 'g / 100 g')),
        _DataRow(label: 'Hidratos de carbono', value: _amount(n.carbohydrates, 'g / 100 g')),
        _DataRow(label: 'Azúcares', value: _amount(n.sugars, 'g / 100 g')),
        _DataRow(label: 'Fibra', value: _amount(n.fiber, 'g / 100 g')),
        _DataRow(label: 'Proteínas', value: _amount(n.proteins, 'g / 100 g')),
        _DataRow(label: 'Sal', value: _amount(n.salt, 'g / 100 g')),
      ];

  String? _amount(num? value, String unit) => value == null ? null : '${value.toString()} $unit';
  String _statusText(CibusStatus status) => status == CibusStatus.insufficient ? 'Datos insuficientes' : 'Análisis en desarrollo';
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
  const _StatusPill({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFE8EEE9), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.science_outlined, size: 18, color: Color(0xFF355E4D)),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF244B3B))),
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
