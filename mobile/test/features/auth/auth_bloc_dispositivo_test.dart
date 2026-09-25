import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:siaa_mobile/core/device/device_info_service.dart';
import 'package:siaa_mobile/core/device/device_metadata.dart';
import 'package:siaa_mobile/features/auth/data/auth_repository.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class FakeAuthRepository extends AuthRepository {
  final DispositivoInfo dispositivoResponse;
  final bool failDeviceRegistration;

  FakeAuthRepository({
    required this.dispositivoResponse,
    this.failDeviceRegistration = false,
  });

  @override
  Future<TokenPair> login({
    required String correo,
    required String password,
  }) async {
    return const TokenPair(
      accessToken: 'fake-jwt-access',
      refreshToken: 'fake-jwt-refresh',
      expiraEn: '2026-12-31T23:59:59Z',
      usuario: UsuarioInfo(
        id: 'usr-1',
        correo: 'docente@univalle.edu.co',
        nombre: 'Carlos',
        apellido: 'Gómez',
        roles: ['DOCENTE'],
        permisos: ['asistencias:crear'],
      ),
    );
  }

  @override
  Future<DispositivoInfo> registrarDispositivo({
    required String instalacionId,
    required String modelo,
    required String so,
    required String versionApp,
  }) async {
    if (failDeviceRegistration) {
      throw Exception('Fallo de red al registrar');
    }
    return dispositivoResponse;
  }
}

class FakeDeviceInfoService extends DeviceInfoService {
  const FakeDeviceInfoService();

  @override
  Future<DeviceMetadata> getMetadata() async {
    return const DeviceMetadata(
      instalacionId: 'inst-1234',
      modelo: 'Pixel Test',
      so: 'Android 14',
      versionApp: '1.0.0',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('AuthBloc - Dispositivo Confiable (US-AUT-03)', () {
    test(
        'emite AuthAuthenticated cuando el dispositivo es aprobado de inmediato',
        () async {
      final fakeRepo = FakeAuthRepository(
        dispositivoResponse: const DispositivoInfo(
          id: 'dev-1',
          estado: 'aprobado',
          mensaje: 'Dispositivo vinculado como principal',
          requiereAprobacion: false,
        ),
      );

      final bloc = AuthBloc(
        repository: fakeRepo,
        deviceInfoService: const FakeDeviceInfoService(),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthAuthenticated>()
              .having((s) => s.usuarioId, 'usuarioId', 'usr-1')
              .having((s) => s.nombre, 'nombre', 'Carlos Gómez'),
        ]),
      );

      bloc.add(const AuthLoginRequested(
        correo: 'docente@univalle.edu.co',
        password: 'password123',
      ));
    });

    test(
        'emite AuthDispositivoPendiente cuando el dispositivo requiere aprobación (AC-03)',
        () async {
      final fakeRepo = FakeAuthRepository(
        dispositivoResponse: const DispositivoInfo(
          id: 'dev-2',
          estado: 'pendiente',
          mensaje:
              'Dispositivo no reconocido. Solicitud enviada al administrador.',
          requiereAprobacion: true,
        ),
      );

      final bloc = AuthBloc(
        repository: fakeRepo,
        deviceInfoService: const FakeDeviceInfoService(),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthDispositivoPendiente>()
              .having((s) => s.dispositivoId, 'dispositivoId', 'dev-2')
              .having((s) => s.mensaje, 'mensaje',
                  contains('Dispositivo no reconocido')),
        ]),
      );

      bloc.add(const AuthLoginRequested(
        correo: 'docente@univalle.edu.co',
        password: 'password123',
      ));
    });
  });
}
