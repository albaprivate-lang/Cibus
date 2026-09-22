import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/product.dart';

class OpenFactsClient {
  OpenFactsClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _userAgent = 'Cibus/0.1 (mobile app; contact: project repository)';

  Future<ProductLookupResult> lookup(String barcode) async {
    final normalized = barcode.replaceAll(RegExp(r'\D'), '');
    if (normalized.length < 8 || normalized.length > 14) {
      return const ProductLookupResult.failure(
        'El código no parece un código de barras válido.',
      );
    }

    try {
      final food = await _fetch(normalized, ProductKind.food);
      if (food != null) return ProductLookupResult.found(food);

      final cosmetic = await _fetch(normalized, ProductKind.cosmetic);
      if (cosmetic != null) return ProductLookupResult.found(cosmetic);

      return const ProductLookupResult.notFound([
        'Open Food Facts',
        'Open Beauty Facts',
      ]);
    } on http.ClientException {
      return const ProductLookupResult.failure(
        'No se pudo conectar con las bases de datos. Comprueba tu conexión.',
      );
    } on FormatException {
      return const ProductLookupResult.failure(
        'La base de datos devolvió una respuesta que no se pudo interpretar.',
      );
    }
  }

  Future<Product?> _fetch(String barcode, ProductKind kind) async {
    final host = kind == ProductKind.food
        ? 'world.openfoodfacts.org'
        : 'world.openbeautyfacts.org';
    final uri = Uri.https(host, '/api/v2/product/$barcode', {
      'fields': [
        'code',
        'product_name',
        'brands',
        'ingredients_text',
        'nutriments',
        'additives_tags',
        'ingredients',
      ].join(','),
    });
    final response = await _httpClient.get(
      uri,
      headers: const {'User-Agent': _userAgent, 'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (json['status'] != 1 || json['product'] is! Map<String, dynamic>) return null;
    return _parseProduct(
      barcode,
      kind,
      uri,
      json['product'] as Map<String, dynamic>,
    );
  }

  Product _parseProduct(
    String barcode,
    ProductKind kind,
    Uri sourceUrl,
    Map<String, dynamic> json,
  ) {
    final nutrients = json['nutriments'] is Map<String, dynamic>
        ? json['nutriments'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final ingredientRows = json['ingredients'] is List
        ? (json['ingredients'] as List).whereType<Map<String, dynamic>>()
        : const Iterable<Map<String, dynamic>>.empty();
    return Product(
      barcode: barcode,
      kind: kind,
      sourceName: kind == ProductKind.food ? 'Open Food Facts' : 'Open Beauty Facts',
      sourceUrl: sourceUrl,
      name: _text(json['product_name']),
      brand: _text(json['brands']),
      ingredients: _text(json['ingredients_text']),
      nutriments: Nutriments(
        energyKcal: _number(nutrients['energy-kcal_100g']),
        fat: _number(nutrients['fat_100g']),
        saturatedFat: _number(nutrients['saturated-fat_100g']),
        carbohydrates: _number(nutrients['carbohydrates_100g']),
        sugars: _number(nutrients['sugars_100g']),
        fiber: _number(nutrients['fiber_100g']),
        proteins: _number(nutrients['proteins_100g']),
        salt: _number(nutrients['salt_100g']),
      ),
      additives: (json['additives_tags'] as List?)
              ?.whereType<String>()
              .map((item) => item.replaceFirst(RegExp(r'^[a-z]{2}:'), '').toUpperCase())
              .toList() ??
          const [],
      ingredientInformation: ingredientRows
          .map((item) => _text(item['text']) ?? _text(item['id']))
          .whereType<String>()
          .toList(),
    );
  }

  String? _text(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  num? _number(Object? value) => value is num ? value : num.tryParse('$value');
}
