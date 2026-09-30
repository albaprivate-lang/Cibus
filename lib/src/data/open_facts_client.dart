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
        'categories_tags',
        'nutrition_data_per',
        'serving_size',
        'last_modified_t',
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
    final categories = (json['categories_tags'] as List?)
            ?.whereType<String>()
            .toList() ??
        const <String>[];
    final isBeverage = kind == ProductKind.food
        ? _isBeverage(categories)
        : null;
    final nutritionDataPer = _text(json['nutrition_data_per']);
    final nutritionBasis = _nutritionBasis(nutritionDataPer, isBeverage);
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
      categories: categories,
      isBeverage: isBeverage,
      nutritionBasis: nutritionBasis,
      servingSize: _text(json['serving_size']),
      lastModified: _dateTime(json['last_modified_t']),
    );
  }

  String? _text(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  num? _number(Object? value) => value is num ? value : num.tryParse('$value');

  bool? _isBeverage(List<String> categories) {
    if (categories.isEmpty) return null;
    // Open Food Facts devuelve la jerarquía completa en categories_tags. Una
    // bebida debería contener el ancestro canónico `en:beverages`. Solo se
    // aceptan etiquetas exactas: buscar sufijos como "-beverages" clasificaría
    // erróneamente `en:plant-based-foods-and-beverages` como bebida.
    const canonicalBeverageCategories = {
      'beverages',
      'waters',
      'juices',
      'soft-drinks',
      'plant-based-beverages',
      'dairy-drinks',
    };
    final normalized = categories.map(
      (category) => category
          .replaceFirst(RegExp(r'^[^:]+:'), '')
          .trim()
          .toLowerCase(),
    ).toSet();
    if (normalized.any(canonicalBeverageCategories.contains)) return true;
    if (normalized.contains('plant-based-foods-and-beverages')) return null;
    return false;
  }

  NutritionBasis _nutritionBasis(String? nutritionDataPer, bool? isBeverage) {
    if (nutritionDataPer == 'serving') return NutritionBasis.perServing;
    if (isBeverage == null) return NutritionBasis.unknown;
    if (nutritionDataPer == '100ml') {
      return isBeverage ? NutritionBasis.per100ml : NutritionBasis.unknown;
    }
    if (nutritionDataPer == '100g') {
      return isBeverage ? NutritionBasis.per100ml : NutritionBasis.per100g;
    }
    return NutritionBasis.unknown;
  }

  DateTime? _dateTime(Object? timestamp) {
    final seconds = _number(timestamp)?.toInt();
    return seconds == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }
}
