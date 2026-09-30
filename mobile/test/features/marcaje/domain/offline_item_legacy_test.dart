// offline_item_legacy_test.dart — Compatibilidad de la cola persistida con el formato anterior (US-MAR-11)
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/data/services/politica_reintentos.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/offline_marcaje_item.dart';

Map<String, dynamic> legado(String estado, {Map<String, dynamic>? res}) => {
      'localId': 'loc-$estado',
      'request': {
        'sesionId': 'ses-1',
        'tipo': 'ENTRADA',
        'latitud': 4.6,
        'longitud': -74.06,
        'precisionMetros': 10,
        'timestampDispositivo': '2026-09-25T07:05:00.000Z',
        'dispositivoId': 'dev-1',
        'versionApp': '1.0.0',
        'integridad': {'mockLocation': false, 'attestationOk': true},
        'idempotencyKey': 'k1',
      },
      'creadoEn': '2026-09-25T07:05:00.000',
      'estado': estado,
      'errorMensaje': 'SocketException',
      'resultadoServidor': res,
    };

void main() {
  group('OfflineMarcajeItem legado', () {
    test('un fallido del formato anterior vuelve a ser pendiente reintentable',
        () {
      final it = OfflineMarcajeItem.fromMap(legado('fallido'));
      expect(it.estado, EstadoSincronizacion.pendiente);
      expect(it.intentos, 0);
      expect(it.proximoIntento, isNull);
      expect(it.esSincronizable(DateTime(2026, 9, 25, 8)), isTrue);
    });

    test('nunca asume attestationOk ni exige attestation en items antiguos',
        () {
      final it = OfflineMarcajeItem.fromMap(legado('pendiente'));
      expect(it.request.integridad.attestationOk, isFalse);
      expect(it.exigirAttestation, isFalse);
      expect(it.request.verificacionComplementaria, isNull);
    });

    test('un sincronizado no aceptado del formato anterior pasa a rechazado',
        () {
      final rech = OfflineMarcajeItem.fromMap(legado('sincronizado',
          res: {'resultado': 'RECHAZADO_FUERA_DE_AREA', 'mensaje': 'Fuera'}));
      expect(rech.estado, EstadoSincronizacion.rechazado);
      final ok = OfflineMarcajeItem.fromMap(legado('sincronizado',
          res: {'resultado': 'PRESENTE', 'mensaje': ''}));
      expect(ok.estado, EstadoSincronizacion.sincronizado);
    });

    test('el formato nuevo conserva intentos, backoff y banderas', () {
      final original = OfflineMarcajeItem.fromMap(legado('pendiente')).copyWith(
        intentos: 3,
        proximoIntento: DateTime(2026, 9, 25, 9),
        estado: EstadoSincronizacion.fallido,
      );
      final restaurado = OfflineMarcajeItem.fromMap(original.toMap());
      expect(restaurado.estado, EstadoSincronizacion.fallido);
      expect(restaurado.intentos, 3);
      expect(restaurado.proximoIntento, DateTime(2026, 9, 25, 9));
    });
  });

  group('PoliticaReintentos', () {
    const politica = PoliticaReintentos();

    test('espera 30 s · 2^(n-1) con tope de 30 min', () {
      expect(politica.espera(1), const Duration(seconds: 30));
      expect(politica.espera(2), const Duration(minutes: 1));
      expect(politica.espera(4), const Duration(minutes: 4));
      expect(politica.espera(7), const Duration(minutes: 30));
      expect(politica.espera(20), const Duration(minutes: 30));
    });

    test('reinicio manual devuelve el item a la cola inmediatamente', () {
      final fallido = OfflineMarcajeItem.fromMap(legado('pendiente'))
          .copyWith(estado: EstadoSincronizacion.fallido, intentos: 8);
      final r = politica.reiniciar(fallido);
      expect(r.estado, EstadoSincronizacion.pendiente);
      expect(r.intentos, 0);
      expect(r.errorMensaje, isNull);
    });
  });
}
