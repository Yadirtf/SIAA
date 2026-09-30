// push_registro_service_test.dart — Registro y baja del token push (US-NOT-01)
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/notificaciones/data/firebase_config.dart';
import 'package:siaa_mobile/features/notificaciones/data/notificaciones_remote_datasource.dart';
import 'package:siaa_mobile/features/notificaciones/data/push_proveedor.dart';
import 'package:siaa_mobile/features/notificaciones/data/push_registro_service.dart';

class MockPush extends Mock implements PushProveedor {}

class MockRemote extends Mock implements NotificacionesRemoteDataSource {}

void main() {
  late MockPush push;
  late MockRemote remote;
  late StreamController<String> renovaciones;
  late PushRegistroService servicio;

  setUp(() {
    push = MockPush();
    remote = MockRemote();
    renovaciones = StreamController<String>.broadcast();
    when(() => push.tokenRenovado).thenAnswer((_) => renovaciones.stream);
    when(() => push.eliminarTokenLocal()).thenAnswer((_) async {});
    when(() => remote.registrarToken(
          token: any(named: 'token'),
          plataforma: any(named: 'plataforma'),
          dispositivoId: any(named: 'dispositivoId'),
        )).thenAnswer((_) async {});
    when(() => remote.eliminarToken(any())).thenAnswer((_) async {});
    servicio = PushRegistroService(
      push: push,
      remote: remote,
      instalacionId: () async => 'inst-1',
      plataforma: () => 'ANDROID',
    );
  });

  tearDown(() => renovaciones.close());

  test('registra el token con plataforma e instalación y re-registra al rotar',
      () async {
    when(() => push.solicitarPermiso()).thenAnswer((_) async => true);
    when(() => push.obtenerToken()).thenAnswer((_) async => 'tok-1');

    await servicio.registrar();
    verify(() => remote.registrarToken(
          token: 'tok-1',
          plataforma: 'ANDROID',
          dispositivoId: 'inst-1',
        )).called(1);

    renovaciones.add('tok-2');
    await Future<void>.delayed(Duration.zero);
    verify(() => remote.registrarToken(
          token: 'tok-2',
          plataforma: 'ANDROID',
          dispositivoId: 'inst-1',
        )).called(1);
  });

  test('sin permiso no registra nada', () async {
    when(() => push.solicitarPermiso()).thenAnswer((_) async => false);
    await servicio.registrar();
    verifyNever(() => push.obtenerToken());
    verifyNever(() => remote.registrarToken(
          token: any(named: 'token'),
          plataforma: any(named: 'plataforma'),
          dispositivoId: any(named: 'dispositivoId'),
        ));
  });

  test('desregistrar elimina el último token registrado', () async {
    when(() => push.solicitarPermiso()).thenAnswer((_) async => true);
    when(() => push.obtenerToken()).thenAnswer((_) async => 'tok-1');
    await servicio.registrar();
    renovaciones.add('tok-2');
    await Future<void>.delayed(Duration.zero);

    await servicio.desregistrar();

    verify(() => remote.eliminarToken('tok-2')).called(1);
    verify(() => push.eliminarTokenLocal()).called(1);
    // Tras la baja, una rotación ya no se registra.
    renovaciones.add('tok-3');
    await Future<void>.delayed(Duration.zero);
    verifyNever(() => remote.registrarToken(
          token: 'tok-3',
          plataforma: any(named: 'plataforma'),
          dispositivoId: any(named: 'dispositivoId'),
        ));
  });

  test('un fallo del DELETE no impide limpiar el token local', () async {
    when(() => push.obtenerToken()).thenAnswer((_) async => 'tok-9');
    when(() => remote.eliminarToken(any())).thenThrow(Exception('red'));
    await servicio.desregistrar();
    verify(() => push.eliminarTokenLocal()).called(1);
  });

  test('sin Firebase el servicio queda deshabilitado y no falla', () async {
    final sinPush = PushRegistroService(remote: remote);
    expect(sinPush.habilitado, isFalse);
    await sinPush.registrar();
    await sinPush.desregistrar();
    verifyZeroInteractions(remote);
  });

  test('FirebaseConfig exige las cuatro dart-defines', () {
    expect(
      FirebaseConfig.desde(
          apiKey: 'k', appId: 'a', messagingSenderId: '', projectId: 'p'),
      isNull,
    );
    final o = FirebaseConfig.desde(
        apiKey: 'k', appId: 'a', messagingSenderId: 's', projectId: 'p');
    expect(o?.projectId, 'p');
    // El build de pruebas no define las variables: push deshabilitado.
    expect(FirebaseConfig.opciones, isNull);
  });
}
