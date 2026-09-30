import 'package:cibus/src/data/open_facts_client.dart';
import 'package:cibus/src/ui/product_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('muestra color, explicación y trazabilidad', (tester) async {
    final client = OpenFactsClient(httpClient: MockClient((request) async {
      return http.Response('''{
        "status": 1,
        "product": {
          "product_name": "Alimento de prueba",
          "categories_tags": ["en:foods"],
          "nutrition_data_per": "100g",
          "serving_size": "30 g",
          "nutriments": {
            "energy-kcal_100g": 100,
            "saturated-fat_100g": 1,
            "sugars_100g": 4,
            "salt_100g": 0.2
          }
        }
      }''', 200);
    }));

    await tester.pumpWidget(MaterialApp(
      home: ProductPage(barcode: '8412345678901', client: client),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Verde · perfil favorable'), findsOneWidget);
    expect(find.textContaining('Azúcares: 4 g/100 g'), findsOneWidget);
    expect(find.text('Método: Cibus Food 1.0.0'), findsOneWidget);
    expect(find.text('30 g'), findsOneWidget);
  });

  testWidgets('detalla la información ausente', (tester) async {
    final client = OpenFactsClient(httpClient: MockClient((request) async {
      return http.Response('''{
        "status": 1,
        "product": {
          "product_name": "Producto incompleto",
          "categories_tags": ["en:foods"],
          "nutrition_data_per": "100g",
          "nutriments": {"energy-kcal_100g": 100}
        }
      }''', 200);
    }));

    await tester.pumpWidget(MaterialApp(
      home: ProductPage(barcode: '8412345678901', client: client),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Datos insuficientes'), findsOneWidget);
    expect(find.text('Falta el dato de azúcares.'), findsOneWidget);
    expect(find.text('Información que falta'), findsOneWidget);
  });
}
