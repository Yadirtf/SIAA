// desbloqueo_biometrico_test.dart — Reapertura con biometría local (US-AUT-06 AC-01..AC-03)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/auth/biometric_auth_service.dart';
import 'package:siaa_mobile/core/auth/preferencia_biometria.dart';
import 'package:siaa_mobile/core/storage/secure_storage.dart';
import 'package:siaa_mobile/features/auth/data/auth_repository.dart';
import 'package:siaa_mobile/features/auth/data/desbloqueo_local.dart';
import 'package:siaa_mobile/features/auth/data/sesion_restaurador.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:siaa_mobile/features/auth/presentation/cubit/desbloqueo_cubit.dart';
import 'package:siaa_mobile/features/auth/presentation/screens/desbloqueo_screen.dart';

import '../../helpers/auth_sesion.dart';

class _RepoSinRed extends AuthRepository {
  String? revocado;
  @override
  Future<void> logout({required String refreshToken}) async =>
      revocado = refreshToken;
}

const _sesion = SesionRestaurada(
  usuarioId: 'u-1',
  nombre: 'Ana Gómez',
  correo: 'ana@siaa.edu.co',
  roles: ['DOCENTE'],
  permisos: ['marcajes:crear'],
  rolActivo: 'DOCENTE',
);

BiometricAuthService _servicio({
  bool biometria = true,
  bool credencial = true,
  List<bool> respuestas = const [true],
  bool credencialOk = true,
}) {
  var i = 0;
  return BiometricAuthService(
    availabilityChecker: () async => biometria,
    dispositivoSeguroChecker: () async => credencial,
    authInvoker: (_) async => respuestas[i++ % respuestas.length],
    credencialInvoker: (_) async => credencialOk,
    tokenFetcher: () async => 'refresh-1',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('DesbloqueoLocal decide si se exige verificación', () {
    DesbloqueoLocal crear({
      String? token = 'refresh-1',
      String? pref,
      bool biometria = false,
      bool credencial = false,
    }) =>
        DesbloqueoLocal(
          servicio: _servicio(biometria: biometria, credencial: credencial),
          preferencia: PreferenciaBiometria(
              leer: () async => pref, escribir: (_) async {}),
          leerRefreshToken: () async => token,
        );

    test('con sesión previa y biometría disponible: se exige (AC-01)',
        () async {
      expect(await crear(biometria: true).requiereDesbloqueo(), isTrue);
    });

    test('sin biometría pero con PIN del dispositivo: se exige (AC-02)',
        () async {
      expect(await crear(credencial: true).requiereDesbloqueo(), isTrue);
    });

    test('sin sesión, desactivada o sin mecanismo local: no bloquea', () async {
      expect(await crear(token: null, biometria: true).requiereDesbloqueo(),
          isFalse);
      expect(await crear(pref: 'false', biometria: true).requiereDesbloqueo(),
          isFalse);
      expect(await crear().requiereDesbloqueo(), isFalse);
    });
  });

  group('AuthBloc', () {
    test('pide desbloqueo y, al superarlo, restaura la sesión guardada',
        () async {
      final bloc = AuthBloc(
        repository: _RepoSinRed(),
        restaurador: RestauradorFijo(_sesion),
        requiereDesbloqueo: () async => true,
      );
      addTearDown(bloc.close);

      bloc.add(AuthSessionChecked());
      await bloc.stream.firstWhere((s) => s is AuthDesbloqueoRequerido);
      bloc.add(AuthDesbloqueoSuperado());
      final s = await bloc.stream.firstWhere((s) => s is AuthAuthenticated);
      expect((s as AuthAuthenticated).usuarioId, 'u-1');
    });

    test('descartar el desbloqueo borra y revoca la sesión (AC-03)', () async {
      await SecureStorage.saveSession(accessToken: 'acc', refreshToken: 'ref');
      final repo = _RepoSinRed();
      final bloc =
          AuthBloc(repository: repo, requiereDesbloqueo: () async => true);
      addTearDown(bloc.close);

      bloc.add(AuthDesbloqueoDescartado());
      await bloc.stream.firstWhere((s) => s is AuthUnauthenticated);
      expect(await SecureStorage.getRefreshToken(), isNull);
      expect(repo.revocado, 'ref');
    });
  });

  group('DesbloqueoCubit', () {
    test('lanza la biometría al iniciar y la supera', () async {
      final cubit = DesbloqueoCubit(servicio: _servicio());
      addTearDown(cubit.close);
      await cubit.iniciar();
      expect(cubit.state.etapa, EtapaDesbloqueo.superado);
    });

    test('tres fallos biométricos exigen contraseña aunque haya PIN (AC-03)',
        () async {
      final cubit =
          DesbloqueoCubit(servicio: _servicio(respuestas: const [false]));
      addTearDown(cubit.close);
      await cubit.iniciar();
      expect(cubit.state.etapa, EtapaDesbloqueo.esperando);
      await cubit.verificarBiometria();
      expect(cubit.state.etapa, EtapaDesbloqueo.esperando);
      await cubit.verificarBiometria();
      expect(cubit.state.etapa, EtapaDesbloqueo.requiereContrasena);
    });

    test('sin biometría ofrece el PIN del dispositivo (AC-02)', () async {
      final cubit = DesbloqueoCubit(servicio: _servicio(biometria: false));
      addTearDown(cubit.close);
      await cubit.iniciar();
      expect(cubit.state.etapa, EtapaDesbloqueo.esperando);
      expect(cubit.state.biometriaDisponible, isFalse);
      await cubit.verificarCredencialDispositivo();
      expect(cubit.state.etapa, EtapaDesbloqueo.superado);
    });
  });

  testWidgets('la pantalla ofrece PIN y contraseña, y el PIN abre la sesión',
      (tester) async {
    final bloc = AuthBloc(
      repository: _RepoSinRed(),
      restaurador: RestauradorFijo(_sesion),
      requiereDesbloqueo: () async => true,
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(BlocProvider.value(
      value: bloc,
      child: MaterialApp(
          home: DesbloqueoScreen(servicio: _servicio(biometria: false))),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Usar huella o rostro'), findsNothing);
    expect(find.text('Ingresar con mi contraseña'), findsOneWidget);
    await tester.tap(find.text('Usar PIN del dispositivo'));
    // Tras superarla queda un indicador de progreso hasta que el router navega.
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(bloc.state, isA<AuthAuthenticated>());
  });
}
