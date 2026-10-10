import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/academico/data/estudiantes_grupo_remote_datasource.dart';
import 'package:siaa_web/features/academico/data/models/estudiante_grupo_model.dart';
import 'package:siaa_web/features/academico/presentation/cubit/estudiantes_grupo_cubit.dart';
import 'package:siaa_web/features/academico/presentation/helpers/identificadores_pegados.dart';

import 'fake_estudiantes_grupo.dart';

void main() {
  test('separarIdentificadores acepta líneas, comas y punto y coma', () {
    expect(separarIdentificadores(' a@x.co\n1002 ; b@x.co,\n\nA@X.CO '), [
      'a@x.co',
      '1002',
      'b@x.co',
    ]);
  });

  test('cargar trae los estudiantes del grupo', () async {
    final cubit = EstudiantesGrupoCubit(
      grupoId: 'g1',
      dataSource: EstudiantesGrupoDsFalso(),
    );
    await cubit.cargar();
    expect(cubit.state.estudiantes, [anaGrupo, luisGrupo]);
    expect(cubit.state.modificado, isFalse);
  });

  test('agregar ignora quienes ya están (id, correo o documento)', () async {
    final cubit = EstudiantesGrupoCubit(
      grupoId: 'g1',
      dataSource: EstudiantesGrupoDsFalso(),
    );
    await cubit.cargar();
    final n = cubit.agregar('1001\nANA@uni.edu.co; nuevo@uni.edu.co, 2002');
    expect(n, 2);
    expect(cubit.state.pendientes, ['nuevo@uni.edu.co', '2002']);
    expect(cubit.agregar('2002'), 0);
    expect(cubit.state.total, 4);
  });

  test('guardar envía la lista completa y publica el resultado', () async {
    final ds = EstudiantesGrupoDsFalso()
      ..respuesta = const ResultadoEstudiantesGrupo(
        estudiantes: [anaGrupo],
        noEncontrados: ['x@uni.edu.co'],
        noEstudiantes: ['2002'],
      );
    final cubit = EstudiantesGrupoCubit(grupoId: 'g1', dataSource: ds);
    await cubit.cargar();
    cubit.quitarEstudiante('u2');
    cubit.agregar('x@uni.edu.co\n2002');
    expect(await cubit.guardar(), isTrue);
    expect(ds.enviados, ['u1', 'x@uni.edu.co', '2002']);
    expect(cubit.state.estudiantes, [anaGrupo]);
    expect(cubit.state.pendientes, isEmpty);
    expect(cubit.state.modificado, isFalse);
    expect(cubit.state.resultado?.noEstudiantes, ['2002']);
  });

  test('guardar conserva la lista y muestra el mensaje del servidor', () async {
    final ds = EstudiantesGrupoDsFalso()
      ..errorAlGuardar = 'El grupo supera el cupo de 1 estudiantes';
    final cubit = EstudiantesGrupoCubit(grupoId: 'g1', dataSource: ds);
    await cubit.cargar();
    cubit.agregar('nuevo@uni.edu.co');
    expect(await cubit.guardar(), isFalse);
    expect(cubit.state.error, 'El grupo supera el cupo de 1 estudiantes');
    expect(cubit.state.pendientes, ['nuevo@uni.edu.co']);
    expect(cubit.state.modificado, isTrue);
  });

  test('el datasource usa GET y PUT sobre /grupos/:id/estudiantes', () async {
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
    final peticiones = <http.Request>[];
    final ds = EstudiantesGrupoRemoteDataSource(
      client: ApiClient(
        client: MockClient((req) async {
          peticiones.add(req);
          final cuerpo = req.method == 'GET'
              ? [
                  {'id': 'u1', 'nombre': 'Ana', 'correo': 'a@x.co'},
                ]
              : {
                  'estudiantes': [
                    {'id': 'u1', 'nombre': 'Ana', 'correo': 'a@x.co'},
                  ],
                  'noEncontrados': ['z@x.co'],
                  'noEstudiantes': [],
                };
          return http.Response(
            jsonEncode(cuerpo),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      ),
    );
    expect((await ds.listar('g1')).single.documento, isNull);
    final r = await ds.reemplazar('g1', ['u1', 'z@x.co']);
    expect(peticiones.map((p) => p.method), ['GET', 'PUT']);
    expect(peticiones.last.url.path, endsWith('/grupos/g1/estudiantes'));
    expect(jsonDecode(peticiones.last.body), {
      'estudiantes': ['u1', 'z@x.co'],
    });
    expect(r.noEncontrados, ['z@x.co']);
  });
}
