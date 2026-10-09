import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/geo/domain/geometria_poligono.dart';

void main() {
  test('el área coincide con la fórmula geodésica del backend', () {
    // Cuadrado de 0.0002° (~22 m) por lado en Mocoa.
    final area = areaGeodesicaM2([
      [-76.6512, 1.1478],
      [-76.6510, 1.1478],
      [-76.6510, 1.1476],
      [-76.6512, 1.1476],
    ]);
    expect(area, closeTo(495, 10));
    expect(
      areaGeodesicaM2([
        [-76.0, 1.0],
        [-76.1, 1.0],
      ]),
      0,
    );
  });

  test('el orden de los vértices no cambia el área', () {
    final horario = [
      [-76.0, 1.0],
      [-76.0, 1.001],
      [-75.999, 1.001],
      [-75.999, 1.0],
    ];
    expect(
      areaGeodesicaM2(horario),
      closeTo(areaGeodesicaM2(horario.reversed.toList()), 1e-6),
    );
  });

  group('aristaMasCercana', () {
    const cuadrado = [
      (x: 0.0, y: 0.0),
      (x: 100.0, y: 0.0),
      (x: 100.0, y: 100.0),
      (x: 0.0, y: 100.0),
    ];

    test('encuentra la arista y la fracción del toque', () {
      final a = aristaMasCercana(cuadrado, (x: 50.0, y: 5.0))!;
      expect(a.indice, 0);
      expect(a.t, closeTo(0.5, 1e-9));
      expect(a.distancia, closeTo(5, 1e-9));
    });

    test('incluye la arista de cierre (último → primero)', () {
      expect(aristaMasCercana(cuadrado, (x: 2.0, y: 60.0))!.indice, 3);
    });

    test('ignora toques lejos de cualquier lado', () {
      expect(aristaMasCercana(cuadrado, (x: 50.0, y: 50.0)), isNull);
      expect(
        aristaMasCercana(cuadrado.sublist(0, 2), (x: 1.0, y: 0.0)),
        isNull,
      );
    });
  });
}
