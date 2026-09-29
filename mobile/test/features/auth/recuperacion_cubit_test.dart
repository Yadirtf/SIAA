import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/auth/data/auth_repository.dart';
import 'package:siaa_mobile/features/auth/presentation/cubit/recuperacion_cubit.dart';
import 'package:siaa_mobile/features/auth/presentation/screens/recuperar_password_screen.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repo;

  setUp(() => repo = _MockAuthRepository());

  blocTest<RecuperacionCubit, RecuperacionState>(
    'solicitar envía el correo y pasa al paso del código',
    build: () {
      when(() => repo.solicitarRecuperacion(correo: any(named: 'correo')))
          .thenAnswer((_) async {});
      return RecuperacionCubit(repo);
    },
    act: (c) => c.solicitar(' docente@siaa.edu.co '),
    expect: () => const [
      RecuperacionState(RecuperacionPaso.enviando),
      RecuperacionState(RecuperacionPaso.codigo),
    ],
    verify: (_) => verify(
      () => repo.solicitarRecuperacion(correo: 'docente@siaa.edu.co'),
    ).called(1),
  );

  blocTest<RecuperacionCubit, RecuperacionState>(
    'confirmar con token inválido conserva el paso y muestra el error',
    build: () {
      when(() => repo.confirmarRecuperacion(
                token: any(named: 'token'),
                password: any(named: 'password'),
              ))
          .thenThrow(const AuthException(
              message: 'Token inválido o expirado', code: 'VALIDACION'));
      return RecuperacionCubit(repo);
    },
    act: (c) =>
        c.confirmar('https://siaa.edu.co/?token=abc123', 'NuevaClave2026'),
    expect: () => const [
      RecuperacionState(RecuperacionPaso.enviando),
      RecuperacionState(RecuperacionPaso.codigo,
          error: 'Token inválido o expirado'),
    ],
    verify: (_) => verify(() => repo.confirmarRecuperacion(
        token: 'abc123', password: 'NuevaClave2026')).called(1),
  );

  test('extraerToken acepta el enlace completo o solo el código', () {
    expect(extraerToken('https://x.co/recuperar?token=t%2B1'), 't+1');
    expect(extraerToken('  codigo-plano '), 'codigo-plano');
  });

  testWidgets('la pantalla valida que las contraseñas coincidan',
      (tester) async {
    await tester.pumpWidget(RepositoryProvider<AuthRepository>.value(
      value: repo,
      child: const MaterialApp(home: RecuperarPasswordScreen()),
    ));
    await tester.tap(find.text('Ya tengo un código'));
    await tester.pump();
    final campos = find.byType(TextFormField);
    expect(campos, findsNWidgets(3));
    await tester.enterText(campos.at(0), 'abc');
    await tester.enterText(campos.at(1), 'NuevaClave2026');
    await tester.enterText(campos.at(2), 'Distinta2026x');
    await tester.tap(find.text('Guardar contraseña'));
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    verifyNever(() => repo.confirmarRecuperacion(
        token: any(named: 'token'), password: any(named: 'password')));
  });
}
