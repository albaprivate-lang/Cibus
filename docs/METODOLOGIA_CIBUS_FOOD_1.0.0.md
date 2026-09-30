# Metodología Cibus Food 1.0.0

## Alcance

Cibus Food 1.0.0 clasifica alimentos en **Verde, Amarillo, Naranja o
Rojo** usando exclusivamente los datos nutricionales declarados por 100 g
(sólidos) o 100 ml (bebidas). El color describe el perfil de los datos
analizados; no es consejo médico ni determina por sí solo cuánto o con qué
frecuencia debe consumirse un alimento.

No se importan ni se usan Nutri-Score, Eco-Score, NOVA u otras puntuaciones de
terceros. Los aditivos tampoco alteran automáticamente el resultado.

## Fuentes normativas

Los límites de azúcares, grasas saturadas y sal proceden de la tabla 2 de la
guía oficial británica *Guide to creating a front of pack (FoP) nutrition
label for pre-packed products sold through retail outlets*, actualización de
noviembre de 2016:

- Department of Health, Food Standards Agency y administraciones
  descentralizadas, [Front of pack nutrition labelling guidance](https://www.gov.uk/government/publications/front-of-pack-nutrition-labelling-guidance).

La densidad energética utiliza dos escalones numéricos que aparecen en la
tabla de puntos A del modelo oficial británico 2004/05: 1005 kJ (240 kcal) y
2680 kJ (640 kcal) por 100 g:

- Department of Health, [Nutrient Profiling Technical Guidance](https://www.gov.uk/government/publications/the-nutrient-profiling-model).

Los factores favorables utilizan los requisitos de las declaraciones «alto
contenido de fibra» (6 g/100 g) y «alto contenido de proteínas» (al menos el
20 % del valor energético) del anexo del Reglamento (CE) 1924/2006:

- Unión Europea, [Reglamento (CE) n.º 1924/2006](https://eur-lex.europa.eu/legal-content/ES/TXT/?uri=CELEX:02006R1924-20141213).

La base por 100 g o 100 ml sigue la forma de expresión de la declaración
nutricional del Reglamento (UE) 1169/2011:

- Unión Europea, [Reglamento (UE) n.º 1169/2011](https://eur-lex.europa.eu/legal-content/ES/TXT/?uri=CELEX:02011R1169-20180101).

Las referencias identifican el origen de los **límites nutricionales**. El
modelo británico no denomina «bajo», «medio» o «alto» a los intervalos de
energía de Cibus: Cibus agrupa dos escalones de su tabla de puntos para crear
esas tres bandas. Tanto esa agrupación energética como la agregación en cuatro
colores descrita abajo son reglas transparentes propias de Cibus, no una
clasificación publicada ni avalada por esos organismos.

## Datos mínimos

Para asignar un color deben existir valores válidos de:

1. energía;
2. azúcares;
3. grasas saturadas;
4. sal;
5. tipo de producto (sólido o bebida); y
6. base nutricional compatible (100 g o 100 ml).

Un dato ausente nunca se interpreta como cero. Se muestra **Datos
insuficientes** con la lista exacta de ausencias o incoherencias.

## Límites por factor

Los límites inferiores son inclusivos. Un valor solo es alto cuando supera el
límite alto, conforme a la guía de etiquetado frontal.

Cibus reutiliza únicamente los cortes por 100 g/100 ml de esa guía. No aplica
sus criterios alternativos por porción: la decisión de ignorar la porción en
la versión 1.0.0 es propia de Cibus y mantiene comparables los productos. Por
ello, el resultado Cibus no debe presentarse como el color del etiquetado
frontal británico.

| Factor | Base | Bajo | Medio | Alto |
|---|---:|---:|---:|---:|
| Azúcares, sólido | 100 g | ≤ 5 g | > 5 y ≤ 22,5 g | > 22,5 g |
| Azúcares, bebida | 100 ml | ≤ 2,5 g | > 2,5 y ≤ 11,25 g | > 11,25 g |
| Saturadas, sólido | 100 g | ≤ 1,5 g | > 1,5 y ≤ 5 g | > 5 g |
| Saturadas, bebida | 100 ml | ≤ 0,75 g | > 0,75 y ≤ 2,5 g | > 2,5 g |
| Sal, sólido | 100 g | ≤ 0,3 g | > 0,3 y ≤ 1,5 g | > 1,5 g |
| Sal, bebida | 100 ml | ≤ 0,3 g | > 0,3 y ≤ 0,75 g | > 0,75 g |
| Energía | base aplicable | ≤ 240 kcal | > 240 y ≤ 640 kcal | > 640 kcal |

En particular, 1005 kJ y 2680 kJ no se presentan como límites oficiales de
una clasificación británica bajo/medio/alto. Son escalones oficiales de la
tabla de puntos que esta versión de Cibus ha elegido como cortes de su propia
clasificación energética.

## Agregación propia de Cibus

1. **Rojo:** dos o más factores altos.
2. **Naranja:** un factor alto o tres o más factores medios.
3. **Amarillo:** uno o dos factores medios y ninguno alto.
4. **Verde:** todos los factores bajos.

Este orden impide que una media o una puntuación total esconda varios excesos.

### Fibra y proteína

Un alto contenido de fibra o proteína puede reducir **una sola posición** un
resultado naranja causado exclusivamente por tres o más factores medios. No
puede reducir un resultado que contenga un factor alto ni convertir amarillo
en verde. Ambas bonificaciones juntas siguen limitadas a una posición.

## Validación

No se calcula un color cuando:

- hay números negativos o no finitos;
- las grasas saturadas superan a las grasas totales declaradas;
- los azúcares superan a los hidratos declarados;
- un macronutriente o la sal supera 100 g en la base declarada;
- solo hay valores por porción; o
- no se puede determinar si corresponde 100 g o 100 ml.

La porción se muestra como información adicional y no altera el resultado.

## Exclusiones de esta versión

Se excluyen bebidas alcohólicas, alimentos y fórmulas infantiles,
complementos alimenticios y sustitutivos de comidas. Los cosméticos conservan
«Análisis en desarrollo». Una categoría excluida no recibe un color.

## Trazabilidad y actualización

La evaluación conserva los valores y unidades usados, su interpretación por
factor y la versión `Cibus Food 1.0.0`. Cualquier cambio de límites o de
agregación requiere una nueva versión de este documento y pruebas de regresión.
