enum ProductKind { food, cosmetic }

enum CibusStatus { excellent, good, improvable, notRecommended, developing, insufficient }

enum ConfidenceLevel { high, medium, low }

class Nutriments {
  const Nutriments({
    this.energyKcal,
    this.fat,
    this.saturatedFat,
    this.carbohydrates,
    this.sugars,
    this.fiber,
    this.proteins,
    this.salt,
  });

  final num? energyKcal;
  final num? fat;
  final num? saturatedFat;
  final num? carbohydrates;
  final num? sugars;
  final num? fiber;
  final num? proteins;
  final num? salt;

  int get availableCount => [
        energyKcal,
        fat,
        saturatedFat,
        carbohydrates,
        sugars,
        fiber,
        proteins,
        salt,
      ].where((value) => value != null).length;
}

class Product {
  const Product({
    required this.barcode,
    required this.kind,
    required this.sourceName,
    required this.sourceUrl,
    this.name,
    this.brand,
    this.ingredients,
    this.nutriments = const Nutriments(),
    this.additives = const [],
    this.ingredientInformation = const [],
  });

  final String barcode;
  final ProductKind kind;
  final String sourceName;
  final Uri sourceUrl;
  final String? name;
  final String? brand;
  final String? ingredients;
  final Nutriments nutriments;
  final List<String> additives;
  final List<String> ingredientInformation;

  int get dataPoints {
    final textCount = [name, brand, ingredients]
        .where((value) => value != null && value!.trim().isNotEmpty)
        .length;
    return textCount + nutriments.availableCount + additives.length;
  }
}

class ProductLookupResult {
  const ProductLookupResult.found(this.product)
      : errorMessage = null,
        searchedSources = const [];

  const ProductLookupResult.notFound(this.searchedSources)
      : product = null,
        errorMessage = null;

  const ProductLookupResult.failure(this.errorMessage)
      : product = null,
        searchedSources = const [];

  final Product? product;
  final String? errorMessage;
  final List<String> searchedSources;

  bool get isFound => product != null;
  bool get isFailure => errorMessage != null;
}
