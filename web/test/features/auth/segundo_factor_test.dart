import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/auth/data/models/segundo_factor_model.dart';
import 'package:siaa_web/features/auth/data/models/user_model.dart';
import 'package:siaa_web/features/auth/domain/auth_repository.dart';
import 'package:siaa_web/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:siaa_web/features/auth/presentation/bloc/auth_event.dart';
import 'package:siaa_web/features/auth/presentation/bloc/auth_state.dart';
import 'package:siaa_web/features/auth/presentation/widgets/segundo_factor_panel.dart';

const _admin = UserModel(
  id: 'u1',
  correo: 'admin@siaa.edu.co',
  nombre: 'Ana',
  apellido: 'Admin',
  roles: ['ADMIN_INSTITUCIONAL'],
  permisos: [],
);

/// Simula el API: el login entrega un desafío y solo el código 123456 lo completa.
class _RepoTotp implements AuthRepository {
  final bool configurar;
  String? codigoRecibido;
  bool enrolado = false;

  _RepoTotp({required this.configurar});

  @override
  Future<LoginResultado> login({
    required String correo,
    required String password,
  }) async => LoginResultado.desafio(
    DesafioTotp(token: 'reto', configurar: configurar),
  );

  @override
  Future<TotpEnrolamiento> enrolarTotp(DesafioTotp desafio) async {
    enrolado = true;
    return const TotpEnrolamiento(
      secreto: 'JBSWY3DPEHPK3PXP',
      codigosRespaldo: ['AAAA1111', 'BBBB2222'],
    );
  }

  @override
  Future<UserModel> completarTotp({
    required DesafioTotp desafio,
    required String codigo,
  }) async {
    codigoRecibido = codigo;
    if (codigo != '123456') {
      throw const ApiException(message: 'Código de autenticación inválido');
    }
    return _admin;
  }

  @override
  Future<UserModel?> checkAuthStatus() async => null;
  @override
  Future<void> logout() async {}
  @override
  Future<void> recuperarPassword({required String correo}) async {}
  @override
  Future<void> confirmarRecuperacion({
    required String token,
    required String newPassword,
  }) async {}
}

Future<AuthState> _esperar(AuthBloc bloc, bool Function(AuthState) cond) =>
    bloc.stream.firstWhere(cond);

void main() {
  test('un administrador sin TOTP debe enrolarlo antes de entrar', () async {
    final repo = _RepoTotp(configurar: true);
    final bloc = AuthBloc(authRepository: repo);
    bloc.add(
      const LoginSubmittedEvent(correo: 'admin@siaa.edu.co', password: 'x'),
    );
    final reto = await _esperar(
      bloc,
      (s) => s is SegundoFactorRequerido,
    ) as SegundoFactorRequerido;
    expect(repo.enrolado, isTrue);
    expect(reto.enrolamiento!.codigosRespaldo, hasLength(2));
    expect(
      reto.enrolamiento!.uri('admin@siaa.edu.co'),
      contains('secret=JBSWY3DPEHPK3PXP'),
    );

    bloc.add(const SegundoFactorEnviadoEvent('000000'));
    final fallo = await _esperar(
      bloc,
      (s) => s is SegundoFactorRequerido && s.error != null,
    ) as SegundoFactorRequerido;
    expect(fallo.error, 'Código de autenticación inválido');

    bloc.add(const SegundoFactorEnviadoEvent(' 123456 '));
    final fin = await _esperar(bloc, (s) => s is Authenticated);
    expect((fin as Authenticated).user, _admin);
    expect(repo.codigoRecibido, '123456');
    await bloc.close();
  });

  test('con TOTP activo solo pide el código y se puede cancelar', () async {
    final repo = _RepoTotp(configurar: false);
    final bloc = AuthBloc(authRepository: repo);
    bloc.add(const LoginSubmittedEvent(correo: 'a@siaa.edu.co', password: 'x'));
    final reto = await _esperar(
      bloc,
      (s) => s is SegundoFactorRequerido,
    ) as SegundoFactorRequerido;
    expect(reto.enrolamiento, isNull);
    expect(repo.enrolado, isFalse);
    bloc.add(const SegundoFactorCanceladoEvent());
    await _esperar(bloc, (s) => s is Unauthenticated);
    await bloc.close();
  });

  testWidgets('el panel muestra clave y códigos y envía el código', (
    tester,
  ) async {
    final bloc = AuthBloc(authRepository: _RepoTotp(configurar: true));
    addTearDown(bloc.close);
    const estado = SegundoFactorRequerido(
      correo: 'admin@siaa.edu.co',
      desafio: DesafioTotp(token: 'reto', configurar: true),
      enrolamiento: TotpEnrolamiento(
        secreto: 'JBSWY3DPEHPK3PXP',
        codigosRespaldo: ['AAAA1111', 'BBBB2222'],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocProvider.value(
              value: bloc,
              child: const SegundoFactorPanel(estado: estado),
            ),
          ),
        ),
      ),
    );
    expect(find.text('JBSWY3DPEHPK3PXP'), findsOneWidget);
    expect(find.text('AAAA1111  BBBB2222'), findsOneWidget);
    expect(find.text('Activar y entrar'), findsOneWidget);
  });
}
