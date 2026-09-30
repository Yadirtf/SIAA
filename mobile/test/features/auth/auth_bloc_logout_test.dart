// auth_bloc_logout_test.dart — Baja del token push antes de limpiar la sesión (US-NOT-01)
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/storage/secure_storage.dart';
import 'package:siaa_mobile/features/auth/data/auth_repository.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class FakeAuthRepository extends AuthRepository {
  @override
  Future<void> logout({required String refreshToken}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test('ejecuta la limpieza con la sesión aún vigente y luego la borra',
      () async {
    await SecureStorage.saveSession(accessToken: 'acc', refreshToken: 'ref');
    String? tokenDuranteLimpieza;
    final bloc = AuthBloc(
      repository: FakeAuthRepository(),
      antesDeCerrarSesion: () async {
        tokenDuranteLimpieza = await SecureStorage.getAccessToken();
      },
    );

    bloc.add(AuthLogoutRequested());
    await expectLater(bloc.stream, emits(isA<AuthUnauthenticated>()));

    expect(tokenDuranteLimpieza, 'acc');
    expect(await SecureStorage.getAccessToken(), isNull);
    await bloc.close();
  });

  test('un fallo en la limpieza no impide cerrar sesión', () async {
    await SecureStorage.saveSession(accessToken: 'acc', refreshToken: 'ref');
    final bloc = AuthBloc(
      repository: FakeAuthRepository(),
      antesDeCerrarSesion: () async => throw Exception('red'),
    );

    bloc.add(AuthLogoutRequested());
    await expectLater(bloc.stream, emits(isA<AuthUnauthenticated>()));
    expect(await SecureStorage.getAccessToken(), isNull);
    await bloc.close();
  });
}
