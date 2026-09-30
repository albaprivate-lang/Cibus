# Cibus

Cibus es una aplicación móvil en Flutter para consultar de forma transparente datos abiertos de alimentos y cosméticos mediante su código de barras. Esta primera versión está orientada a Android y mantiene una base multiplataforma preparada para una futura versión iOS.

> **Estado:** prototipo funcional. Los alimentos con datos suficientes reciben una clasificación nutricional propia, explicable y versionada. Cuando faltan datos o la categoría no está cubierta se muestra **Datos insuficientes**.

## Funcionalidad incluida

- Escaneo de EAN/UPC con la cámara del teléfono.
- Consulta primero en [Open Food Facts](https://world.openfoodfacts.org/) y, si no hay un alimento, en [Open Beauty Facts](https://world.openbeautyfacts.org/).
- Ficha de alimentos con ingredientes, nutrientes por 100 g, aditivos, código y fuente cuando los datos existen.
- Ficha de cosméticos con INCI, información disponible de ingredientes, código y fuente.
- Separación visual entre los **datos aportados por la fuente** y la **valoración propia de Cibus**.
- Clasificación Verde, Amarillo, Naranja o Rojo para alimentos evaluables.
- Explicación «¿Por qué?» con cada valor, unidad y nivel utilizado.
- Lista exacta de datos ausentes o incoherentes cuando no se puede valorar.
- Estado explícito para productos ausentes; nunca se completan campos inventando información.

La presencia de un aditivo o número E no genera por sí misma ninguna penalización. No se importan Nutri-Score, Eco-Score, NOVA ni puntuaciones de otras aplicaciones como valoración Cibus.

## Metodología nutricional

La metodología [Cibus Food 1.0.0](docs/METODOLOGIA_CIBUS_FOOD_1.0.0.md) documenta el alcance, las fuentes oficiales de cada umbral, la validación de datos y la regla propia de agregación. Usa valores por 100 g para sólidos y por 100 ml para bebidas; la porción se muestra únicamente como contexto.

La clasificación describe el perfil de los datos analizados y no sustituye consejo médico. No tiene en cuenta alergias, patologías, necesidades individuales ni la cantidad total consumida.

## Arquitectura

```text
lib/
├── main.dart
└── src/
    ├── app.dart                  # tema y raíz de la aplicación
    ├── data/open_facts_client.dart
    ├── domain/                   # producto y valoración explicable
    └── ui/                       # inicio, escáner y resultado
```

Esta separación permite incorporar después servicios de fotografía/OCR, comparación, alternativas, evidencias científicas e historial sin acoplarlos a la interfaz actual.

## Desarrollo local

Requisitos: [Flutter estable](https://docs.flutter.dev/get-started/install) con Android SDK configurado y un dispositivo Android físico o emulador.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

La cámara y la conexión a las APIs requieren un dispositivo con acceso a Internet. Android solicitará permiso de cámara al abrir el escáner.

## Obtener el APK

### Desde GitHub Actions

1. Abre la pestaña **Actions** del repositorio.
2. Selecciona el workflow **Android APK**.
3. Abre la ejecución más reciente correcta (o pulsa **Run workflow**).
4. En **Artifacts**, descarga `cibus-android-debug`.
5. Descomprime el archivo e instala `app-debug.apk` en un dispositivo Android que permita instalar aplicaciones desde esa fuente.

El artefacto de prueba se conserva durante 14 días. Cada *push* a `main`/`work` y cada *pull request* ejecuta análisis, pruebas y compilación.

### Compilación manual

```bash
flutter build apk --debug
```

El APK queda en `build/app/outputs/flutter-apk/app-debug.apk`. Es una compilación de depuración y no está preparada para publicación en Google Play.

## Privacidad y datos

El código leído se envía a Open Food Facts y, si no se encuentra allí, a Open Beauty Facts. Cibus no requiere cuenta ni almacena historial en esta versión. Los datos de esas plataformas son colaborativos y pueden estar incompletos; conviene contrastarlos con el envase.
