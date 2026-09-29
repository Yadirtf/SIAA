import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/usuarios/data/models/usuario_model.dart';
import 'package:siaa_web/features/usuarios/presentation/bloc/catalogo_usuarios_cubit.dart';
import 'package:siaa_web/features/usuarios/presentation/bloc/importacion_usuarios_bloc.dart';
import 'package:siaa_web/features/usuarios/presentation/bloc/usuarios_bloc.dart';
import 'package:siaa_web/features/usuarios/presentation/screens/usuarios_screen.dart';

import '../bloc/fake_usuarios_repository.dart';

void main() {
  testWidgets('lista usuarios y abre el diálogo de nuevo usuario', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1600, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = FakeUsuariosRepository()
      ..usuarios = [
        const UsuarioModel(
          id: 'u1',
          correo: 'ana@uni.edu.co',
          nombre: 'Ana',
          apellido: 'Pérez',
          documento: '1020',
          activo: true,
          bloqueado: true,
          roles: ['DOCENTE', 'MONITOR'],
        ),
      ];

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => UsuariosBloc(repository: repo)),
          BlocProvider(create: (_) => CatalogoUsuariosCubit(repository: repo)),
          BlocProvider(
            create: (_) => ImportacionUsuariosBloc(repository: repo),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: UsuariosScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('ana@uni.edu.co'), findsOneWidget);
    expect(find.text('MONITOR'), findsOneWidget);
    expect(find.text('Bloqueado'), findsOneWidget);

    await tester.tap(find.text('Nuevo usuario'));
    await tester.pumpAndSettle();
    expect(find.text('Crear usuario'), findsOneWidget);
    expect(find.text('Contraseña inicial (opcional)'), findsOneWidget);
  });
}
