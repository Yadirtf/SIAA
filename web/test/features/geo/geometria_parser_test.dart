import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/geo/data/models/geo_models.dart';
import 'package:siaa_web/features/geo/data/models/geometria_parser.dart';
import 'package:siaa_web/features/geo/presentation/editor/ir_a_coordenadas.dart';

void main() {
  group('verticesDesdeGeometria', () {
    test('quita el vértice de cierre y conserva [lon, lat]', () {
      final v = verticesDesdeGeometria({
        'tipo': 'Polygon',
        'coordinates': [
          [
            [-76.1, 1.1],
            [-76.2, 1.1],
            [-76.2, 1.2],
            [-76.1, 1.1],
          ],
        ],
      });
      expect(v, [
        [-76.1, 1.1],
        [-76.2, 1.1],
        [-76.2, 1.2],
      ]);
    });

    test('sin geometría devuelve lista vacía', () {
      expect(verticesDesdeGeometria(null), isEmpty);
      expect(verticesDesdeGeometria({'coordinates': []}), isEmpty);
    });

    test('EspacioModel expone tieneGeometria', () {
      final sin = EspacioModel.fromJson({'id': 'e1'});
      expect(sin.tieneGeometria, isFalse);
      final con = EspacioModel.fromJson({
        'id': 'e2',
        'geometria': {
          'coordinates': [
            [
              [-76.1, 1.1],
              [-76.2, 1.1],
              [-76.2, 1.2],
              [-76.1, 1.1],
            ],
          ],
        },
      });
      expect(con.tieneGeometria, isTrue);
      expect(con.vertices.length, 3);
    });
  });

  group('parsearLatLon', () {
    test('acepta el formato que copia Google Maps', () {
      final p = parsearLatLon('1.14771, -76.65112');
      expect(p?.latitud, 1.14771);
      expect(p?.longitud, -76.65112);
    });

    test('rechaza texto inválido o fuera de rango', () {
      expect(parsearLatLon('hola'), isNull);
      expect(parsearLatLon('95, 10'), isNull);
      expect(parsearLatLon('1.1'), isNull);
    });
  });
}
