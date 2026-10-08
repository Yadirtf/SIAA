import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/auth/data/models/segundo_factor_model.dart';
import 'package:siaa_web/features/auth/data/models/user_model.dart';
import 'package:siaa_web/features/auth/domain/auth_repository.dart';
import 'package:siaa_web/features/auth/presentation/cubit/recuperacion_cubit.dart';
import 'package:siaa_web/features/auth/presentation/screens/recuperar_password_screen.dart';
import 'package:siaa_web/features/auth/presentation/widgets/recuperacion_campos.dart';

class FakeAuthRepository implements AuthRepository {
  String? correoSolicitado;
  String? tokenConfirmado;
  String? claveConfirmada;
  bool fallar = false;

  @override
  Future<void> recuperarPassword({required String correo}) async {
    correoSolicitado = correo;
  }

  @override
  Future<void> confirmarRecuperacion({
    required String token,
    required String newPassword,
  }) async {
    if (fallar) {
      throw const ApiException(message: 'Token inválido o expirado');
    }
    tokenConfirmado = token;
    claveConfirmada = newPassword;
  }

  @override
  Future<LoginResultado> login({
    required String correo,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<TotpEnrolamiento> enrolarTotp(DesafioTotp desafio) =>
      throw UnimplementedError();

  @override
  Future<UserModel> completarTotp({
    required DesafioTotp desafio,
    required String codigo,
  }) => throw UnimplementedError();

  @override
  Future<UserModel?> checkAuthStatus() async => null;

  @override
  Future<void> logout() async {}
}

void main() {
  group('RecuperacionCubit', () {
    test('solicitar envía el correo sin espacios y avisa', () async {
      final repo = FakeAuthRepository();
      final cubit = RecuperacionCubit(repo);
      await cubit.solicitar('  docente@siaa.edu.co ');
      expect(repo.correoSolicitado, 'docente@siaa.edu.co');
      expect(cubit.state.paso, RecuperacionPaso.solicitudEnviada);
    });

    test(
      'confirmar con token inválido muestra el mensaje del servidor',
      () async {
        final repo = FakeAuthRepository()..fallar = true;
        final cubit = RecuperacionCubit(repo);
        await cubit.confirmar('tok', 'NuevaClave2026');
        expect(cubit.state.paso, RecuperacionPaso.error);
        expect(cubit.state.mensaje, 'Token inválido o expirado');
      },
    );
  });

  test('validarNuevaClave aplica la política del backend', () {
    expect(validarNuevaClave('corta'), isNotNull);
    expect(validarNuevaClave('sinmayusculas123'), isNotNull);
    expect(validarNuevaClave('NuevaClave2026'), isNull);
  });

  testWidgets('con token pide y confirma la nueva contraseña', (tester) async {
    final repo = FakeAuthRepository();
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: const MaterialApp(home: RecuperarPasswordScreen(token: 'abc')),
      ),
    );
    final campos = find.byType(TextFormField);
    expect(campos, findsNWidgets(2));
    await tester.enterText(campos.at(0), 'NuevaClave2026');
    await tester.enterText(campos.at(1), 'OtraClave2026');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    expect(repo.tokenConfirmado, isNull);

    await tester.enterText(campos.at(1), 'NuevaClave2026');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pumpAndSettle();
    expect(repo.tokenConfirmado, 'abc');
    expect(find.text('Contraseña actualizada'), findsOneWidget);
  });
}
