// marcaje_sync_service_test.dart — Sincronización por lotes de la cola offline (US-MAR-11)
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/marcaje/data/datasources/marcaje_local_datasource.dart';
import 'package:siaa_mobile/features/marcaje/data/datasources/marcaje_remote_datasource.dart';
import 'package:siaa_mobile/features/marcaje/data/services/attestation_service.dart';
import 'package:siaa_mobile/features/marcaje/data/services/marcaje_sync_service.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/item_sync_resultado_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_request_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/offline_marcaje_item.dart';

class MockRemote extends Mock implements MarcajeRemoteDataSource {}

class MockAttestation extends Mock implements AttestationService {}

MarcajeRequestModel req(String sesion, {String tipo = 'ENTRADA'}) =>
    MarcajeRequestModel(
      sesionId: sesion,
      tipo: tipo,
      latitud: 4.6,
      longitud: -74.06,
      precisionMetros: 8,
      timestampDispositivo: DateTime.utc(2026, 9, 25, 7, 5),
      dispositivoId: 'dev-1',
      versionApp: '1.0.0',
      idempotencyKey: 'k-$sesion',
    );

ItemSyncResultadoModel ok(String s) => ItemSyncResultadoModel(
    sesionId: s, tipo: 'ENTRADA', exitoso: true, resultado: 'PRESENTE');

DioException dioError({int? status}) => DioException(
      requestOptions: RequestOptions(path: '/marcajes/sync'),
      type: status == null
          ? DioExceptionType.connectionError
          : DioExceptionType.badResponse,
      response: status == null
          ? null
          : Response(
              requestOptions: RequestOptions(path: '/marcajes/sync'),
              statusCode: status,
              data: {'mensaje': 'Lote offline inválido'},
            ),
    );

void main() {
  late MockRemote remote;
  late MockAttestation attestation;
  late MarcajeLocalDataSource local;
  late DateTime ahora;
  late MarcajeSyncService servicio;

  setUpAll(() => registerFallbackValue(<MarcajeRequestModel>[]));

  setUp(() async {
    remote = MockRemote();
    attestation = MockAttestation();
    local = MarcajeLocalDataSource();
    await local.limpiarCola();
    ahora = DateTime(2026, 9, 25, 8);
    servicio = MarcajeSyncService(
      remote: remote,
      local: local,
      attestation: attestation,
      reloj: () => ahora,
    );
  });

  tearDown(() => local.limpiarCola());

  Future<OfflineMarcajeItem> item(String s) async =>
      (await local.obtenerTodos()).firstWhere((i) => i.request.sesionId == s);

  test('mapea por orden: aceptado, rechazado y error de item', () async {
    await local.encolarMarcaje(req('s1'));
    await local.encolarMarcaje(req('s2'));
    await local.encolarMarcaje(req('s3'));
    when(() => remote.sincronizarLote(any())).thenAnswer((_) async => [
          const ItemSyncResultadoModel(
              sesionId: 's1',
              tipo: 'ENTRADA',
              exitoso: true,
              resultado: 'TARDANZA',
              marcajeId: 'm1',
              requiereRevision: true),
          const ItemSyncResultadoModel(
              sesionId: 's2',
              tipo: 'ENTRADA',
              exitoso: false,
              resultado: 'RECHAZADO_FUERA_DE_HORARIO',
              motivoRechazo: 'FUERA_DE_HORARIO',
              mensaje: 'Fuera de la ventana'),
          const ItemSyncResultadoModel(
              sesionId: 's3', tipo: 'ENTRADA', exitoso: false, error: 'db'),
        ]);

    final resumen = await servicio.sincronizar();

    expect(resumen.aceptados, 1);
    expect(resumen.rechazados, 1);
    expect(resumen.reprogramados, 1);
    final a = await item('s1');
    expect(a.estado, EstadoSincronizacion.sincronizado);
    expect(a.resultadoServidor?.marcajeId, 'm1');
    expect(a.requiereRevision, isTrue);
    final r = await item('s2');
    expect(r.estado, EstadoSincronizacion.rechazado);
    expect(r.resultadoServidor?.mensaje, 'Fuera de la ventana');
    expect(r.resultadoServidor?.puedeJustificar, isTrue);
    final e = await item('s3');
    expect(e.estado, EstadoSincronizacion.pendiente);
    expect(e.intentos, 1);
    expect(e.proximoIntento, ahora.add(const Duration(seconds: 30)));
  });

  test('error de red reprograma con backoff y agota a fallido tras 8 intentos',
      () async {
    await local.encolarMarcaje(req('s1'));
    when(() => remote.sincronizarLote(any())).thenThrow(dioError());

    await servicio.sincronizar();
    var it = await item('s1');
    expect(it.intentos, 1);
    expect(it.estado, EstadoSincronizacion.pendiente);

    // Antes de vencer el backoff no se reenvía.
    await servicio.sincronizar();
    verify(() => remote.sincronizarLote(any())).called(1);

    for (var n = 2; n <= 8; n++) {
      ahora = ahora.add(const Duration(minutes: 31));
      await servicio.sincronizar();
    }
    it = await item('s1');
    expect(it.intentos, 8);
    expect(it.estado, EstadoSincronizacion.fallido);
  });

  test('5xx reintenta; 4xx marca fallido; 401 deja la cola intacta', () async {
    await local.encolarMarcaje(req('s1'));
    when(() => remote.sincronizarLote(any())).thenThrow(dioError(status: 401));
    await servicio.sincronizar();
    expect((await item('s1')).intentos, 0);

    when(() => remote.sincronizarLote(any())).thenThrow(dioError(status: 503));
    await servicio.sincronizar();
    expect((await item('s1')).estado, EstadoSincronizacion.pendiente);
    expect((await item('s1')).intentos, 1);

    ahora = ahora.add(const Duration(minutes: 5));
    when(() => remote.sincronizarLote(any())).thenThrow(dioError(status: 400));
    await servicio.sincronizar();
    final it = await item('s1');
    expect(it.estado, EstadoSincronizacion.fallido);
    expect(it.errorMensaje, 'Lote offline inválido');
  });

  test('divide en lotes de máximo 50 items', () async {
    for (var i = 0; i < 120; i++) {
      await local.encolarMarcaje(req('s$i'));
    }
    final tamanos = <int>[];
    when(() => remote.sincronizarLote(any())).thenAnswer((inv) async {
      final lote = inv.positionalArguments.first as List<MarcajeRequestModel>;
      tamanos.add(lote.length);
      return lote.map((r) => ok(r.sesionId)).toList();
    });

    final resumen = await servicio.sincronizar();

    expect(tamanos, [50, 50, 20]);
    expect(resumen.aceptados, 120);
  });

  test('pide token fresco solo para items que exigen attestation', () async {
    await local.encolarMarcaje(req('s1'), exigirAttestation: true);
    await local.encolarMarcaje(req('s2'));
    when(() => attestation.obtenerToken(
          sesionId: any(named: 'sesionId'),
          tipo: any(named: 'tipo'),
          idempotencyKey: any(named: 'idempotencyKey'),
        )).thenAnswer((_) async => 'tok-fresco');
    List<MarcajeRequestModel>? enviado;
    when(() => remote.sincronizarLote(any())).thenAnswer((inv) async {
      enviado = inv.positionalArguments.first as List<MarcajeRequestModel>;
      return [ok('s1'), ok('s2')];
    });

    await servicio.sincronizar();

    expect(enviado![0].integridad.attestationToken, 'tok-fresco');
    expect(enviado![1].integridad.attestationToken, isNull);
    verify(() => attestation.obtenerToken(
        sesionId: 's1', tipo: 'ENTRADA', idempotencyKey: 'k-s1')).called(1);
  });

  test('nunca ejecuta dos sincronizaciones en paralelo', () async {
    await local.encolarMarcaje(req('s1'));
    when(() => remote.sincronizarLote(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return [ok('s1')];
    });

    final a = servicio.sincronizar();
    final b = servicio.sincronizar();
    expect(identical(a, b), isTrue);
    await Future.wait([a, b]);
    verify(() => remote.sincronizarLote(any())).called(1);
  });

  test('poda aceptados con más de 7 días y conserva el resto', () async {
    final viejo = await local.encolarMarcaje(req('viejo'));
    final reciente = await local.encolarMarcaje(req('reciente'));
    final rechazado = await local.encolarMarcaje(req('rech'));
    await local.actualizarItems([
      viejo.copyWith(
          estado: EstadoSincronizacion.sincronizado,
          sincronizadoEn: ahora.subtract(const Duration(days: 8))),
      reciente.copyWith(
          estado: EstadoSincronizacion.sincronizado,
          sincronizadoEn: ahora.subtract(const Duration(days: 2))),
      rechazado.copyWith(
          estado: EstadoSincronizacion.rechazado,
          sincronizadoEn: ahora.subtract(const Duration(days: 30))),
    ]);

    await servicio.sincronizar();

    final ids = (await local.obtenerTodos()).map((i) => i.request.sesionId);
    expect(ids, containsAll(['reciente', 'rech']));
    expect(ids, isNot(contains('viejo')));
    verifyNever(() => remote.sincronizarLote(any()));
  });
}
