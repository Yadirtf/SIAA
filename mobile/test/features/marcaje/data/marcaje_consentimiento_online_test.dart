// marcaje_consentimiento_online_test.dart — Ubicación y envío sin consentimiento (US-LEG-01, CA-011)
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/marcaje/data/datasources/marcaje_remote_datasource.dart';
import 'package:siaa_mobile/features/marcaje/data/services/location_service.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_request_model.dart';
import 'package:siaa_mobile/features/privacidad/data/consentimiento_requerido.dart';

class MockGeolocator extends Mock implements GeolocatorPlatform {}

class MockDio extends Mock implements Dio {}

void main() {
  group('LocationService', () {
    test('sin consentimiento nunca consulta ni solicita el permiso', () async {
      final geo = MockGeolocator();
      final servicio = LocationService(
        geolocator: geo,
        consentimientoOtorgado: () => false,
      );

      final r = await servicio.capturarUbicacionPuntual();

      expect(r.error, LocationService.mensajeSinConsentimiento);
      verifyZeroInteractions(geo);
    });

    test('con consentimiento sí verifica el permiso', () async {
      final geo = MockGeolocator();
      when(() => geo.isLocationServiceEnabled()).thenAnswer((_) async => true);
      when(() => geo.checkPermission())
          .thenAnswer((_) async => LocationPermission.deniedForever);
      final servicio = LocationService(
        geolocator: geo,
        consentimientoOtorgado: () => true,
      );

      final r = await servicio.capturarUbicacionPuntual();

      expect(r.hasError, isTrue);
      verify(() => geo.checkPermission()).called(1);
      verifyNever(() => geo.requestPermission());
    });
  });

  test('POST /marcajes con 403 CONSENTIMIENTO_REQUERIDO lanza excepción tipada',
      () async {
    final dio = MockDio();
    when(() => dio.post(
          '/marcajes',
          data: any(named: 'data'),
          options: any(named: 'options'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/marcajes'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/marcajes'),
        statusCode: 403,
        data: {'codigo': 'CONSENTIMIENTO_REQUERIDO', 'mensaje': 'Acepte'},
      ),
    ));
    final remote = MarcajeRemoteDataSource(dio: dio);

    expect(
      () => remote.enviarMarcaje(MarcajeRequestModel(
        sesionId: 's1',
        tipo: 'ENTRADA',
        latitud: 1,
        longitud: 1,
        precisionMetros: 5,
        timestampDispositivo: DateTime(2026),
        dispositivoId: 'd',
        versionApp: '1',
        idempotencyKey: 'k',
      )),
      throwsA(isA<ConsentimientoRequeridoException>()
          .having((e) => e.mensaje, 'mensaje', 'Acepte')),
    );
  });
}
