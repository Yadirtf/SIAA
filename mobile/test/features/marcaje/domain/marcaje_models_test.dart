// marcaje_models_test.dart — Pruebas unitarias de modelos de dominio de marcaje
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_historial_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_request_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_result_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/offline_marcaje_item.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';

void main() {
  group('SesionActivaModel (US-MAR-01)', () {
    test('deserializa correctamente detalle de sesión activa con ventana abierta', () {
      final json = {
        'sesion': {
          'id': 'ses-101',
          'asignatura': 'Cálculo Diferencial',
          'grupo': 'G2',
          'espacio': {
            'id': 'esp-301',
            'codigo': 'A-301',
            'nombre': 'Aula 301',
          },
          'inicioProgramado': '2026-09-25T07:00:00Z',
          'finProgramado': '2026-09-25T09:00:00Z',
          'modalidad': 'PRESENCIAL',
        },
        'ventana': {
          'abreEn': '2026-09-25T06:45:00Z',
          'cierraEn': '2026-09-25T07:15:00Z',
          'estado': 'ABIERTA',
          'minutosParaAbrir': 0,
        },
        'verificacionComplementariaExigida': false,
        'marcajeExistente': null,
      };

      final model = SesionActivaModel.fromDetalleJson(json);

      expect(model.id, equals('ses-101'));
      expect(model.asignatura, equals('Cálculo Diferencial'));
      expect(model.grupo, equals('G2'));
      expect(model.espacio.codigo, equals('A-301'));
      expect(model.ventana.estaAbierta, isTrue);
      expect(model.tieneMarcajeEntrada, isFalse);
    });
  });

  group('MarcajeResultModel (US-MAR-03, US-MAR-06)', () {
    test('deserializa correctamente resultado rechazado con mensaje accionable', () {
      final json = {
        'marcajeId': 'mar-555',
        'resultado': 'RECHAZADO',
        'motivoRechazo': 'FUERA_DE_POLIGONO',
        'mensaje': 'Ubicación registrada a 45.2m fuera del perímetro.',
        'distanciaMetros': 45.2,
        'minutosRespectoInicio': 8,
        'precisionRecibida': 6.5,
        'precisionRequerida': 30.0,
        'permiteReintento': true,
        'puedeJustificar': true,
        'pasoFallido': 7,
      };

      final res = MarcajeResultModel.fromJson(json);

      expect(res.esRechazado, isTrue);
      expect(res.motivoRechazo, equals('FUERA_DE_POLIGONO'));
      expect(res.distanciaMetros, equals(45.2));
      expect(res.permiteReintento, isTrue);
      expect(res.puedeJustificar, isTrue);
      expect(res.pasoFallido, equals(7));
    });
  });

  group('OfflineMarcajeItem (US-MAR-11)', () {
    test('serializa y deserializa en mapa correctamente', () {
      final req = MarcajeRequestModel(
        sesionId: 'ses-1',
        tipo: 'ENTRADA',
        latitud: 4.601,
        longitud: -74.066,
        precisionMetros: 12.0,
        timestampDispositivo: DateTime.utc(2026, 9, 25, 7, 5),
        dispositivoId: 'dev-uuid-1',
        versionApp: '1.0.0',
      );

      final item = OfflineMarcajeItem(
        localId: 'loc-1',
        request: req,
        creadoEn: DateTime.utc(2026, 9, 25, 7, 5),
        estado: EstadoSincronizacion.pendiente,
      );

      final map = item.toMap();
      final restored = OfflineMarcajeItem.fromMap(map);

      expect(restored.localId, equals('loc-1'));
      expect(restored.request.sesionId, equals('ses-1'));
      expect(restored.estado, equals(EstadoSincronizacion.pendiente));
    });
  });

  group('MarcajeHistorialItem (US-MAR-08)', () {
    test('deserializa correctamente un item de historial con evidencia', () {
      final json = {
        'id': 'mar-888',
        'sesionId': 'ses-101',
        'tipo': 'ENTRADA',
        'resultado': 'ACEPTADO',
        'origen': 'MOVIL_ONLINE',
        'asignatura': 'Física Mecánica',
        'grupo': 'G1',
        'espacioCodigo': 'LAB-102',
        'timestampServidor': '2026-09-25T07:05:00Z',
        'evidencia': {
          'ubicacion': {
            'type': 'Point',
            'coordinates': [-74.0665, 4.6012],
          },
          'precision': 8.4,
          'distanciaAlPoligono': 0.0,
          'timestampDispositivo': '2026-09-25T07:04:58Z',
        },
      };

      final item = MarcajeHistorialItem.fromJson(json);

      expect(item.id, equals('mar-888'));
      expect(item.esAceptado, isTrue);
      expect(item.longitud, equals(-74.0665));
      expect(item.latitud, equals(4.6012));
      expect(item.precisionMetros, equals(8.4));
    });
  });
}
