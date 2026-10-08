// mi_asistencia_test.dart — "Mi asistencia" del estudiante en el perfil (US-MAR-13 AC-05)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/navigation/presentation/bloc/nav_bloc.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:siaa_mobile/features/perfil/data/asistencia_remote_datasource.dart';
import 'package:siaa_mobile/features/perfil/data/perfil_remote_datasource.dart';
import 'package:siaa_mobile/features/perfil/domain/asistencia_asignatura.dart';
import 'package:siaa_mobile/features/perfil/domain/perfil_model.dart';
import 'package:siaa_mobile/features/perfil/presentation/cubit/mi_asistencia_cubit.dart';
import 'package:siaa_mobile/features/perfil/presentation/screens/perfil_screen.dart';

import '../../helpers/auth_sesion.dart';

final _json = [
  {
    'grupoId': 'g1',
    'grupo': 'A1',
    'asignaturaId': 'a1',
    'asignatura': 'Cálculo I',
    'sesionesDictadas': 8,
    'sesionesAsistidas': 7,
    'porcentaje': 87.5,
    'umbral': 80,
    'bajoUmbral': false,
  },
  {
    'grupoId': 'g2',
    'grupo': 'B1',
    'asignaturaId': 'a2',
    'asignatura': 'Física',
    'sesionesDictadas': 10,
    'sesionesAsistidas': 6,
    'porcentaje': 60,
    'umbral': 80,
    'bajoUmbral': true,
  },
  {
    'grupoId': 'g3',
    'grupo': 'C1',
    'asignaturaId': 'a3',
    'asignatura': 'Ética',
    'sesionesDictadas': 0,
    'sesionesAsistidas': 0,
    'porcentaje': 0,
    'umbral': 80,
    'bajoUmbral': false,
  },
];

class _AsistenciaFake extends AsistenciaRemoteDataSource {
  final Object? error;
  int llamadas = 0;
  _AsistenciaFake({this.error}) : super(dio: Dio());

  @override
  Future<List<AsistenciaAsignatura>> miAsistencia() async {
    llamadas++;
    if (error != null) throw error!;
    return _json.map(AsistenciaAsignatura.fromJson).toList();
  }
}

class _PerfilFake extends PerfilRemoteDataSource {
  final PerfilModel perfil;
  _PerfilFake(this.perfil) : super(dio: Dio());

  @override
  Future<PerfilModel?> obtener() async => perfil;
}

Future<void> _pumpPerfil(
    WidgetTester tester, List<String> roles, _AsistenciaFake fake) async {
  final auth = await tester.runAsync(() => authBlocCon(const [], roles: roles));
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: auth!),
      BlocProvider(create: (_) => NavBloc()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: PerfilScreen(
          remote:
              _PerfilFake(PerfilModel(id: 'u-1', nombre: 'Ana', roles: roles)),
          instalacionId: () async => 'inst',
          asistenciaRemote: fake,
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test('el modelo formatea el porcentaje con coma decimal', () {
    final a = AsistenciaAsignatura.fromJson(_json.first);
    expect(a.porcentajeTexto, '87,5 %');
    expect(AsistenciaAsignatura.fromJson(_json[1]).porcentajeTexto, '60 %');
    expect(AsistenciaAsignatura.fromJson(_json[2]).sinClases, isTrue);
  });

  test('el cubit expone el mensaje de error del servidor', () async {
    final req = RequestOptions(path: '/me/asistencia');
    final cubit = MiAsistenciaCubit(
      remote: _AsistenciaFake(
        error: DioException(
          requestOptions: req,
          response: Response(
              requestOptions: req,
              statusCode: 500,
              data: {'mensaje': 'No pudimos calcular tu asistencia'}),
        ),
      ),
    );
    await cubit.cargar();
    expect(cubit.state.cargando, isFalse);
    expect(cubit.state.error, 'No pudimos calcular tu asistencia');
    await cubit.close();
  });

  testWidgets('el estudiante ve su asistencia por asignatura', (tester) async {
    final fake = _AsistenciaFake();
    await _pumpPerfil(tester, const ['ESTUDIANTE'], fake);
    await tester.scrollUntilVisible(find.text('Ética'), 100);
    expect(find.text('Mi asistencia'), findsOneWidget);
    expect(find.text('87,5 %'), findsOneWidget);
    expect(find.text('Estás por debajo del 80 % mínimo de asistencia.'),
        findsOneWidget);
    expect(find.text('Grupo C1 · Sin clases dictadas aún'), findsOneWidget);
  });

  testWidgets('el docente no ve la sección ni consulta /me/asistencia',
      (tester) async {
    final fake = _AsistenciaFake();
    await _pumpPerfil(tester, const ['DOCENTE'], fake);
    expect(find.text('Mi asistencia'), findsNothing);
    expect(fake.llamadas, 0);
  });
}
