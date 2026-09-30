import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/domain/models/validacion_geometria_model.dart';

void main() {
  group('ValidacionGeometriaModel (US-GEO-04, T-GEO-04.3)', () {
    test('deserializa correctamente respuesta exitosa sin conflictos', () {
      final json = {
        'valido': true,
        'codigo': '',
        'mensaje': 'Geometría válida',
        'areaM2': 150.75,
        'conflictos': [],
      };

      final model = ValidacionGeometriaModel.fromJson(json);

      expect(model.valido, isTrue);
      expect(model.codigo, isEmpty);
      expect(model.mensaje, 'Geometría válida');
      expect(model.areaM2, 150.75);
      expect(model.conflictos, isEmpty);
    });

    test(
        'deserializa correctamente respuesta con conflictos de auto-interseccion',
        () {
      final json = {
        'valido': false,
        'codigo': 'POLIGONO_NO_SIMPLE',
        'mensaje': 'El polígono tiene auto-intersecciones',
        'areaM2': 0.0,
        'conflictos': [
          {
            'indiceA': 0,
            'indiceB': 2,
            'tipo': 'auto_interseccion',
            'descripcion': 'El segmento 0 se cruza con el segmento 2',
          }
        ],
      };

      final model = ValidacionGeometriaModel.fromJson(json);

      expect(model.valido, isFalse);
      expect(model.codigo, 'POLIGONO_NO_SIMPLE');
      expect(model.areaM2, 0.0);
      expect(model.conflictos.length, 1);

      final conflicto = model.conflictos.first;
      expect(conflicto.indiceA, 0);
      expect(conflicto.indiceB, 2);
      expect(conflicto.tipo, 'auto_interseccion');
      expect(conflicto.descripcion, contains('segmento 0'));
    });

    test('toJson y props soportan igualdad estructural con Equatable', () {
      const model1 = ValidacionGeometriaModel(
        valido: true,
        areaM2: 50.0,
        conflictos: [
          ConflictoSegmentoModel(
            indiceA: 1,
            indiceB: 2,
            tipo: 'test',
            descripcion: 'desc',
          ),
        ],
      );

      const model2 = ValidacionGeometriaModel(
        valido: true,
        areaM2: 50.0,
        conflictos: [
          ConflictoSegmentoModel(
            indiceA: 1,
            indiceB: 2,
            tipo: 'test',
            descripcion: 'desc',
          ),
        ],
      );

      expect(model1, equals(model2));
      expect(model1.toJson()['areaM2'], 50.0);
    });
  });
}
