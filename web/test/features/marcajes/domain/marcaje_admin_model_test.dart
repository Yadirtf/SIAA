// marcaje_admin_model_test.dart — Pruebas unitarias de modelos de marcaje en web
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/marcajes/domain/models/marcaje_admin_model.dart';

void main() {
  group('MarcajeAdminModel (US-MAR-09, US-MAR-10)', () {
    test('deserializa correctamente un marcaje aceptado sin anomalías', () {
      final json = {
        'id': 'mar-web-1',
        'sesionId': 'ses-10',
        'usuarioId': 'usr-20',
        'asignatura': 'Inteligencia Artificial',
        'tipo': 'ENTRADA',
        'resultado': 'ACEPTADO',
        'origen': 'MOVIL_ONLINE',
        'timestampServidor': '2026-09-25T07:02:00Z',
        'evidencia': {
          'ubicacion': {
            'type': 'Point',
            'coordinates': [-74.066, 4.601],
          },
          'precision': 5.2,
          'distanciaAlPoligono': 0.0,
          'timestampDispositivo': '2026-09-25T07:01:59Z',
          'desfaseRelojSegundos': 1,
          'dispositivoId': 'dev-1',
          'integridadFlags': {
            'mockLocation': false,
            'rooteado': false,
            'emulador': false,
            'saltoImposible': false,
          },
        },
        'anulado': false,
      };

      final model = MarcajeAdminModel.fromJson(json);

      expect(model.id, equals('mar-web-1'));
      expect(model.esAceptado, isTrue);
      expect(model.tieneAnomalia, isFalse);
      expect(model.latitud, equals(4.601));
      expect(model.longitud, equals(-74.066));
      expect(model.anulado, isFalse);
    });

    test('detecta anomalías de mock location y salto imposible (US-MAR-10)', () {
      final json = {
        'id': 'mar-web-anomalo',
        'sesionId': 'ses-10',
        'usuarioId': 'usr-fraud',
        'tipo': 'ENTRADA',
        'resultado': 'RECHAZADO',
        'origen': 'MOVIL_ONLINE',
        'timestampServidor': '2026-09-25T07:05:00Z',
        'evidencia': {
          'ubicacion': {'type': 'Point', 'coordinates': [0.0, 0.0]},
          'integridadFlags': {
            'mockLocation': true,
            'saltoImposible': true,
          },
        },
      };

      final model = MarcajeAdminModel.fromJson(json);

      expect(model.tieneAnomalia, isTrue);
      expect(model.mockLocation, isTrue);
      expect(model.saltoImposible, isTrue);
    });

    test('deserializa página completa en MarcajeAdminPageModel', () {
      final json = {
        'marcajes': [
          {
            'id': 'm1',
            'sesionId': 's1',
            'usuarioId': 'u1',
            'tipo': 'ENTRADA',
            'resultado': 'ACEPTADO',
            'origen': 'MOVIL_ONLINE',
            'timestampServidor': '2026-09-25T07:00:00Z',
          }
        ],
        'total': 1,
        'pagina': 1,
        'limite': 20,
      };

      final page = MarcajeAdminPageModel.fromJson(json);
      expect(page.total, equals(1));
      expect(page.items.length, equals(1));
      expect(page.items.first.id, equals('m1'));
    });
  });
}
