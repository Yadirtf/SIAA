// perfil_test.dart — Perfil con dispositivo vinculado y respaldo en la sesión (§9.1)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/navigation/presentation/bloc/nav_bloc.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:siaa_mobile/features/perfil/data/perfil_remote_datasource.dart';
import 'package:siaa_mobile/features/perfil/domain/perfil_model.dart';
import 'package:siaa_mobile/features/perfil/presentation/cubit/perfil_cubit.dart';
import 'package:siaa_mobile/features/perfil/presentation/screens/perfil_screen.dart';

import '../../helpers/auth_sesion.dart';

const _json = {
  'id': 'u-1',
  'nombre': 'Ana',
  'apellido': 'Gómez',
  'correo': 'ana@siaa.edu.co',
  'documento': '1020304050',
  'roles': ['DOCENTE', 'COORDINADOR'],
  'totpActivado': true,
  'dispositivos': [
    {
      'instalacionId': 'inst-actual',
      'modelo': 'Pixel 8',
      'so': 'Android 15',
      'versionApp': '1.0.0',
      'confiable': true,
      'pendienteAprobacion': false,
      'vinculadoEn': '2026-09-01T10:00:00Z'
    },
    {
      'instalacionId': 'inst-vieja',
      'modelo': 'Moto G',
      'so': 'Android 12',
      'versionApp': '0.9.0',
      'confiable': false,
      'pendienteAprobacion': false,
      'vinculadoEn': '2026-01-01T10:00:00Z',
      'revocadoEn': '2026-08-01T10:00:00Z'
    },
  ],
};

class _RemoteFake extends PerfilRemoteDataSource {
  final PerfilModel? perfil;
  _RemoteFake(this.perfil) : super(dio: Dio());

  @override
  Future<PerfilModel?> obtener() async => perfil;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test('PerfilModel parsea roles y dispositivos', () {
    final p = PerfilModel.fromJson(_json);
    expect(p.nombreCompleto, 'Ana Gómez');
    expect(p.dispositivos.first.estadoEtiqueta, 'Confiable');
    expect(p.dispositivos.last.estadoEtiqueta, 'Revocado');
  });

  test('con 404 (backend antiguo) conserva los datos de la sesión', () async {
    const sesion = PerfilModel(id: 'u-1', nombre: 'Ana Gómez', completo: false);
    final cubit = PerfilCubit(
      desdeSesion: sesion,
      instalacionId: () async => 'inst-actual',
      remote: _RemoteFake(null),
    );
    await cubit.cargar();
    expect(cubit.state.perfil, sesion);
    expect(cubit.state.aviso, isNotNull);
    expect(cubit.state.cargando, isFalse);
    await cubit.close();
  });

  testWidgets(
      'marca este dispositivo, lista roles y ofrece privacidad y cierre',
      (tester) async {
    final auth =
        await tester.runAsync(() => authBlocCon(const [], roles: ['DOCENTE']));
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: auth!),
        BlocProvider(create: (_) => NavBloc()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PerfilScreen(
            remote: _RemoteFake(PerfilModel.fromJson(_json)),
            instalacionId: () async => 'inst-actual',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Ana Gómez'), findsOneWidget);
    expect(find.text('Coordinador'), findsOneWidget);
    expect(find.text('Este dispositivo'), findsOneWidget);
    expect(find.text('Revocado'), findsOneWidget);
    expect(find.text('Privacidad y datos'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cerrar sesión'), 100);
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('¿Está seguro de que desea salir del sistema SIAA?'),
        findsOneWidget);
  });
}
