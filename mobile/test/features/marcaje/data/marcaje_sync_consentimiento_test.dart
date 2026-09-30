// marcaje_sync_consentimiento_test.dart — 403 CONSENTIMIENTO_REQUERIDO en la cola offline (US-LEG-01)
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/marcaje/data/datasources/marcaje_local_datasource.dart';
import 'package:siaa_mobile/features/marcaje/data/datasources/marcaje_remote_datasource.dart';
import 'package:siaa_mobile/features/marcaje/data/services/attestation_service.dart';
import 'package:siaa_mobile/features/marcaje/data/services/marcaje_sync_service.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_request_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/offline_marcaje_item.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/resumen_sincronizacion.dart';

class MockRemote extends Mock implements MarcajeRemoteDataSource {}

class MockAttestation extends Mock implements AttestationService {}

MarcajeRequestModel req(String sesion) => MarcajeRequestModel(
      sesionId: sesion,
      tipo: 'ENTRADA',
      latitud: 4.6,
      longitud: -74.06,
      precisionMetros: 8,
      timestampDispositivo: DateTime.utc(2026, 9, 25, 7, 5),
      dispositivoId: 'dev-1',
      versionApp: '1.0.0',
      idempotencyKey: 'k-$sesion',
    );

DioException error403(String codigo) => DioException(
      requestOptions: RequestOptions(path: '/marcajes/sync'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/marcajes/sync'),
        statusCode: 403,
        data: {'codigo': codigo, 'mensaje': 'Debe aceptar el aviso'},
      ),
    );

void main() {
  late MockRemote remote;
  late MarcajeLocalDataSource local;
  late int avisos;
  late MarcajeSyncService servicio;

  setUpAll(() => registerFallbackValue(<MarcajeRequestModel>[]));

  setUp(() async {
    remote = MockRemote();
    local = MarcajeLocalDataSource();
    await local.limpiarCola();
    avisos = 0;
    servicio = MarcajeSyncService(
      remote: remote,
      local: local,
      attestation: MockAttestation(),
      reloj: () => DateTime(2026, 9, 25, 8),
      onConsentimientoRequerido: () async => avisos++,
    );
  });

  tearDown(() => local.limpiarCola());

  test('403 CONSENTIMIENTO_REQUERIDO deja los items pendientes sin intento',
      () async {
    await local.encolarMarcaje(req('s1'));
    await local.encolarMarcaje(req('s2'));
    when(() => remote.sincronizarLote(any()))
        .thenThrow(error403('CONSENTIMIENTO_REQUERIDO'));

    final resumen = await servicio.sincronizar();

    expect(resumen, ResumenSincronizacion.vacio);
    expect(avisos, 1);
    final items = await local.obtenerTodos();
    expect(items, hasLength(2));
    for (final it in items) {
      expect(it.estado, EstadoSincronizacion.pendiente);
      expect(it.intentos, 0);
      expect(it.proximoIntento, isNull);
    }

    // Tras aceptar, el siguiente intento los envía de inmediato.
    when(() => remote.sincronizarLote(any())).thenAnswer((_) async => []);
    await servicio.sincronizar();
    verify(() => remote.sincronizarLote(any())).called(2);
  });

  test('otro 403 sigue siendo un fallo definitivo del lote', () async {
    await local.encolarMarcaje(req('s1'));
    when(() => remote.sincronizarLote(any()))
        .thenThrow(error403('PERMISO_DENEGADO'));

    await servicio.sincronizar();

    expect(avisos, 0);
    final it = (await local.obtenerTodos()).single;
    expect(it.estado, EstadoSincronizacion.fallido);
  });
}
