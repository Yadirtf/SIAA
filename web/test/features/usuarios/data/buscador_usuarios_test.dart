import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/usuarios/data/buscador_usuarios.dart';
import 'package:siaa_web/features/usuarios/data/usuarios_remote_datasource.dart';
import 'package:siaa_web/features/usuarios/presentation/widgets/selector_usuario.dart';

void main() {
  late List<http.Request> peticiones;

  BuscadorUsuariosRemoto crear(http.Response Function(http.Request) responder) {
    final client = MockClient((req) async {
      peticiones.add(req);
      return responder(req);
    });
    return BuscadorUsuariosRemoto(
      remote: UsuariosRemoteDataSource(client: ApiClient(client: client)),
    );
  }

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  test('buscar consulta docentes activos por texto y lee el JSON', () async {
    final buscador = crear(
      (_) => http.Response(
        jsonEncode([
          {
            'id': 'u-7',
            'correo': 'ana.perez@uni.edu.co',
            'nombre': 'Ana',
            'apellido': 'Pérez',
            'documento': '1012345',
            'activo': true,
            'roles': ['DOCENTE'],
          },
        ]),
        200,
        headers: {
          'x-total-count': '1',
          'content-type': 'application/json; charset=utf-8',
        },
      ),
    );

    final usuarios = await buscador.buscar(' ana ', rol: 'DOCENTE');

    final q = peticiones.single.url.queryParameters;
    expect(peticiones.single.url.path, endsWith('/usuarios'));
    expect(q['q'], 'ana');
    expect(q['rol'], 'DOCENTE');
    expect(q['activo'], 'true');
    expect(q['limite'], '20');
    expect(usuarios.single.id, 'u-7');
    expect(SelectorUsuario.nombre(usuarios.single), 'Ana Pérez');
    expect(
      SelectorUsuario.detalle(usuarios.single),
      'ana.perez@uni.edu.co · Doc. 1012345',
    );
  });

  test('buscar sin texto ni filtro de estado omite q y activo', () async {
    final buscador = crear((_) => http.Response('[]', 200));
    await buscador.buscar('', soloActivos: false);
    final q = peticiones.single.url.queryParameters;
    expect(q.containsKey('q'), isFalse);
    expect(q.containsKey('activo'), isFalse);
    expect(q.containsKey('rol'), isFalse);
  });

  test('porId devuelve el usuario o null si no existe', () async {
    final buscador = crear(
      (req) => req.url.path.endsWith('/u-1')
          ? http.Response(
              jsonEncode({'id': 'u-1', 'correo': 'x@uni.edu.co'}),
              200,
            )
          : http.Response(jsonEncode({'mensaje': 'no existe'}), 404),
    );
    expect((await buscador.porId('u-1'))?.correo, 'x@uni.edu.co');
    expect(await buscador.porId('u-404'), isNull);
  });
}
