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
  });

  test('rechaza códigos no válidos sin consultar la red', () async {
    final result = await OpenFactsClient().lookup('ABC');
    expect(result.isFailure, isTrue);
  });
}
