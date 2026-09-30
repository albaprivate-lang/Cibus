import 'package:cibus/src/data/open_facts_client.dart';
import 'package:cibus/src/domain/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

void main() {
  test('consulta y transforma un alimento de Open Food Facts', () async {
    final client = OpenFactsClient(httpClient: MockClient((request) async {
      expect(request.url.host, 'world.openfoodfacts.org');
      return http.Response('''{
        "status": 1,
        "product": {
          "product_name": "Leche de avena",
          "brands": "Ejemplo",
          "ingredients_text": "Agua, avena",
          "categories_tags": ["en:plant-based-beverages"],
          "nutrition_data_per": "100g",
          "serving_size": "250 ml",
          "last_modified_t": 1700000000,
          "nutriments": {"energy-kcal_100g": 42, "sugars_100g": 3.1},
          "additives_tags": ["en:e300"]
        }
      }''', 200, headers: {'content-type': 'application/json; charset=utf-8'});
    }));

    final result = await client.lookup('8412345678901');

    expect(result.isFound, isTrue);
    expect(result.product!.name, 'Leche de avena');
    expect(result.product!.kind, ProductKind.food);
    expect(result.product!.nutriments.sugars, 3.1);
    expect(result.product!.additives, ['E300']);
    expect(result.product!.isBeverage, isTrue);
    expect(result.product!.nutritionBasis, NutritionBasis.per100ml);
    expect(result.product!.servingSize, '250 ml');
    expect(result.product!.lastModified, isNotNull);
  });

  test('rechaza códigos no válidos sin consultar la red', () async {
    final result = await OpenFactsClient().lookup('ABC');
    expect(result.isFailure, isTrue);
  });

  test('no confunde una categoría mixta con una bebida', () async {
    final client = OpenFactsClient(httpClient: MockClient((request) async {
      return http.Response('''{
        "status": 1,
        "product": {
          "categories_tags": ["en:plant-based-foods-and-beverages"],
          "nutrition_data_per": "100g",
          "nutriments": {}
        }
      }''', 200);
    }));

    final result = await client.lookup('8412345678901');

    expect(result.product!.isBeverage, isNull);
    expect(result.product!.nutritionBasis, NutritionBasis.unknown);
  });

  test('conserva porción y ausencias sin convertirlas en cero', () async {
    final client = OpenFactsClient(httpClient: MockClient((request) async {
      return http.Response('''{
        "status": 1,
        "product": {
          "categories_tags": ["en:beverages"],
          "nutrition_data_per": "serving",
          "nutriments": {"energy-kcal_serving": 50}
        }
      }''', 200);
    }));

    final result = await client.lookup('8412345678901');

    expect(result.product!.nutritionBasis, NutritionBasis.perServing);
    expect(result.product!.nutriments.energyKcal, isNull);
    expect(result.product!.nutriments.sugars, isNull);
  });
}
