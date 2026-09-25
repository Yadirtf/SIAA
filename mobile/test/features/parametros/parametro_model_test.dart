import 'package:flutter_test/flutter_test.dart';

import 'package:siaa_mobile/features/parametros/domain/models/parametro_model.dart';

void main() {
  group('ParametroEfectivo', () {
    test('fromJson parsea correctamente un parámetro numérico', () {
      final json = {
        'clave': 'precision_gps_max_metros',
        'valor': 35,
        'nivel': 'GLOBAL',
        'nivel_id': '',
      };
      final p = ParametroEfectivo.fromJson(json);
      expect(p.clave, 'precision_gps_max_metros');
      expect(p.valor, 35);
      expect(p.esGlobal, isTrue);
      expect(p.valorFormateado, '35');
      expect(p.nivelLabel, 'Global');
    });

    test('fromJson parsea un parámetro booleano correctamente', () {
      final json = {
        'clave': 'offline_permitido',
        'valor': true,
        'nivel': 'SEDE',
        'nivel_id': 'sede-001',
      };
      final p = ParametroEfectivo.fromJson(json);
      expect(p.esGlobal, isFalse);
      expect(p.valorFormateado, 'Sí');
      expect(p.nivelLabel, 'Sede');
    });

    test('nivelLabel retorna etiquetas correctas para todos los niveles', () {
      final niveles = {
        'GLOBAL': 'Global',
        'SEDE': 'Sede',
        'FACULTAD': 'Facultad',
        'BLOQUE': 'Bloque',
        'AULA': 'Aula',
        'ASIGNACION': 'Asignación',
      };
      for (final entry in niveles.entries) {
        final p = ParametroEfectivo(
          clave: 'test',
          valor: 1,
          nivel: entry.key,
          nivelId: '',
        );
        expect(p.nivelLabel, entry.value, reason: 'Falla para nivel ${entry.key}');
      }
    });
  });

  group('ParametrosSnapshot', () {
    test('fromJson construye el snapshot con todos los parámetros', () {
      final json = {
        'parametros': [
          {'clave': 'buffer_perimetral_metros', 'valor': 10, 'nivel': 'GLOBAL', 'nivel_id': ''},
          {'clave': 'umbral_tardanza_min', 'valor': 5, 'nivel': 'SEDE', 'nivel_id': 's1'},
        ],
      };
      final snap = ParametrosSnapshot.fromJson(json);
      expect(snap.parametros.length, 2);
    });

    test('porClave retorna el parámetro correcto', () {
      final snap = ParametrosSnapshot(
        parametros: [
          const ParametroEfectivo(
            clave: 'buffer_perimetral_metros',
            valor: 10,
            nivel: 'GLOBAL',
            nivelId: '',
          ),
        ],
      );
      final p = snap.porClave('buffer_perimetral_metros');
      expect(p, isNotNull);
      expect(p!.valor, 10);
    });

    test('porClave retorna null para clave inexistente', () {
      final snap = ParametrosSnapshot(parametros: []);
      expect(snap.porClave('clave_inexistente'), isNull);
    });
  });
}
