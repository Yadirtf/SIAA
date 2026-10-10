import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/device/device_info_service.dart';
import 'package:siaa_mobile/core/device/device_metadata.dart';
import 'package:siaa_mobile/features/auth/data/auth_repository.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';

const _usuario = UsuarioInfo(
  id: 'usr-coord',
  correo: 'coordinador@siaa.edu.co',
  nombre: 'Lina',
  apellido: 'Coord',
  roles: ['COORDINADOR'],
  permisos: [],
);

/// Simula el API con segundo factor obligatorio: solo 123456 completa el desafío.
class _RepoTotp extends AuthRepository {
  final bool configurar;
  bool enrolado = false;
  _RepoTotp({required this.configurar});

  @override
  Future<TokenPair> login(
          {required String correo, required String password}) async =>
      TokenPair(
        accessToken: '',
        refreshToken: '',
        expiraEn: '',
        usuario: const UsuarioInfo(
            id: '',
            correo: '',
            nombre: '',
            apellido: '',
            roles: [],
            permisos: []),
        desafio: DesafioTotp(token: 'reto', configurar: configurar),
      );

  @override
  Future<TotpEnrolamiento> enrolarTotp(DesafioTotp desafio) async {
    enrolado = true;
    return const TotpEnrolamiento(
        secreto: 'JBSWY3DPEHPK3PXP', codigosRespaldo: ['AAAA1111']);
  }

  @override
  Future<TokenPair> completarTotp({
    required DesafioTotp desafio,
    required String codigo,
  }) async {
    if (codigo != '123456') {
      throw const AuthException(
          message: 'Código de autenticación inválido',
          code: 'AUTH_CREDENCIALES_INVALIDAS');
    }
    return const TokenPair(
        accessToken: 'a', refreshToken: 'r', expiraEn: '', usuario: _usuario);
  }

  @override
  Future<DispositivoInfo> registrarDispositivo({
    required String instalacionId,
    required String modelo,
    required String so,
    required String versionApp,
  }) async =>
      const DispositivoInfo(id: 'dev-1');
}

class _Device extends DeviceInfoService {
  const _Device();
  @override
  Future<DeviceMetadata> getMetadata() async => const DeviceMetadata(
      instalacionId: 'i', modelo: 'm', so: 's', versionApp: '1');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test('un coordinador sin TOTP lo enrola y luego entra con el código',
      () async {
    final repo = _RepoTotp(configurar: true);
    final bloc = AuthBloc(repository: repo, deviceInfoService: const _Device());
    bloc.add(const AuthLoginRequested(
        correo: 'coordinador@siaa.edu.co', password: 'x'));
    final reto =
        await bloc.stream.firstWhere((s) => s is AuthSegundoFactorRequerido)
            as AuthSegundoFactorRequerido;
    expect(repo.enrolado, isTrue);
    expect(reto.enrolamiento!.secreto, 'JBSWY3DPEHPK3PXP');

    bloc.add(const AuthSegundoFactorEnviado('000000'));
    final fallo = await bloc.stream.firstWhere(
            (s) => s is AuthSegundoFactorRequerido && s.error != null)
        as AuthSegundoFactorRequerido;
    expect(fallo.error, 'Código de autenticación inválido');

    bloc.add(const AuthSegundoFactorEnviado('123456'));
    final fin = await bloc.stream.firstWhere((s) => s is AuthAuthenticated)
        as AuthAuthenticated;
    expect(fin.usuarioId, 'usr-coord');
    await bloc.close();
  });

  test('con TOTP activo no enrola y se puede cancelar', () async {
    final repo = _RepoTotp(configurar: false);
    final bloc = AuthBloc(repository: repo, deviceInfoService: const _Device());
    bloc.add(const AuthLoginRequested(correo: 'c@siaa.edu.co', password: 'x'));
    await bloc.stream.firstWhere((s) => s is AuthSegundoFactorRequerido);
    expect(repo.enrolado, isFalse);
    bloc.add(AuthSegundoFactorCancelado());
    await bloc.stream.firstWhere((s) => s is AuthUnauthenticated);
    await bloc.close();
  });
}
