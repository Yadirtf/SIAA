import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/dispositivos/domain/models/dispositivo_model.dart';

void main() {
  group('DispositivoModel (US-AUT-03)', () {
    test(
      'deserializa correctamente un dispositivo aprobado desde DTO del backend',
      () {
        final json = {
          'id': 'disp-01',
          'usuarioId': 'usr-100',
          'instalacionId': 'inst-uuid-1234',
          'modelo': 'Google Pixel 8',
          'so': 'Android 14',
          'versionApp': '1.0.0+2',
          'confiable': true,
          'pendienteAprobacion': false,
          'creadoEn': '2026-03-01T10:00:00Z',
          'actualizadoEn': '2026-03-01T10:00:00Z',
          'revocadoEn': null,
        };

        final model = DispositivoModel.fromJson(json);

        expect(model.id, 'disp-01');
        expect(model.usuarioId, 'usr-100');
        expect(model.instalacionId, 'inst-uuid-1234');
        expect(model.modelo, 'Google Pixel 8');
        expect(model.so, 'Android 14');
        expect(model.versionApp, '1.0.0+2');
        expect(model.confiable, isTrue);
        expect(model.pendienteAprobacion, isFalse);
        expect(model.esAprobado, isTrue);
        expect(model.esPendiente, isFalse);
        expect(model.esRevocado, isFalse);
        expect(model.estadoTexto, 'Aprobado');
        expect(model.creadoEn, isNotNull);
        expect(model.revocadoEn, isNull);
      },
    );

    test('reconoce correctamente estado Pendiente de Aprobación', () {
      final json = {
        'id': 'disp-02',
        'usuarioId': 'usr-100',
        'instalacionId': 'inst-uuid-5678',
        'modelo': 'iPhone 15 Pro',
        'so': 'iOS 17.4',
        'versionApp': '1.0.0',
        'confiable': false,
        'pendienteAprobacion': true,
        'creadoEn': '2026-03-02T12:00:00Z',
        'actualizadoEn': '2026-03-02T12:00:00Z',
      };

      final model = DispositivoModel.fromJson(json);

      expect(model.esPendiente, isTrue);
      expect(model.esAprobado, isFalse);
      expect(model.esRevocado, isFalse);
      expect(model.estadoTexto, 'Pendiente');
    });

    test(
      'reconoce correctamente estado Revocado cuando revocadoEn no es nulo',
      () {
        final json = {
          'id': 'disp-03',
          'usuarioId': 'usr-100',
          'instalacionId': 'inst-uuid-9999',
          'modelo': 'Samsung Galaxy S23',
          'so': 'Android 13',
          'versionApp': '1.0.0',
          'confiable': false,
          'pendienteAprobacion': false,
          'creadoEn': '2026-02-15T08:00:00Z',
          'revocadoEn': '2026-03-01T15:30:00Z',
        };

        final model = DispositivoModel.fromJson(json);

        expect(model.esRevocado, isTrue);
        expect(model.esAprobado, isFalse);
        expect(model.esPendiente, isFalse);
        expect(model.estadoTexto, 'Revocado');
      },
    );

    test('props soporta comparación estructural con Equatable', () {
      const d1 = DispositivoModel(
        id: '1',
        usuarioId: 'u1',
        instalacionId: 'inst-1',
        modelo: 'M',
        so: 'S',
        versionApp: '1.0',
        confiable: true,
        pendienteAprobacion: false,
      );
      const d2 = DispositivoModel(
        id: '1',
        usuarioId: 'u1',
        instalacionId: 'inst-1',
        modelo: 'M',
        so: 'S',
        versionApp: '1.0',
        confiable: true,
        pendienteAprobacion: false,
      );

      expect(d1, equals(d2));
    });
  });
}
