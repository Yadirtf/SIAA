import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/usuarios/data/models/usuario_requests.dart';
import 'package:siaa_web/features/usuarios/data/usuarios_remote_datasource.dart';

void main() {
  late List<http.Request> peticiones;

  UsuariosRemoteDataSource crear(
    http.Response Function(http.Request) responder,
  ) {
    final client = MockClient((req) async {
      peticiones.add(req);
      return responder(req);
    });
    return UsuariosRemoteDataSource(client: ApiClient(client: client));
  }

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  test('listar envía filtros y lee X-Total-Count', () async {
    final ds = crear(
      (_) => http.Response(
        jsonEncode([
          {'id': 'u1', 'correo': 'a@uni.edu.co', 'activo': true},
        ]),
        200,
        headers: {'x-total-count': '120', 'content-type': 'application/json'},
      ),
    );

    final pagina = await ds.listar(
      texto: 'ana',
      rol: 'DOCENTE',
      activo: true,
      pagina: 2,
    );

    final q = peticiones.single.url.queryParameters;
    expect(q, {
      'q': 'ana',
      'rol': 'DOCENTE',
      'activo': 'true',
      'pagina': '2',
      'limite': '50',
    });
    expect(peticiones.single.headers['Authorization'], 'Bearer tok');
    expect(pagina.total, 120);
    expect(pagina.totalPaginas, 3);
    expect(pagina.hayMas, isTrue);
  });

  test('importar envía el CSV crudo como text/csv', () async {
    final ds = crear(
      (_) => http.Response(
        jsonEncode({
          'confirmado': false,
          'total': 1,
          'validas': 1,
          'creados': 0,
          'filas': [],
        }),
        200,
      ),
    );

    await ds.importar('correo,nombre\na@uni.edu.co,A\n', confirmar: false);

    final req = peticiones.single;
    expect(req.url.path, endsWith('/usuarios/importar'));
    expect(req.url.queryParameters['confirmar'], 'false');
    expect(req.headers['Content-Type'], startsWith('text/csv'));
    expect(req.body, 'correo,nombre\na@uni.edu.co,A\n');
  });

  test('crear expone invitacionEnviada y los errores con su mensaje', () async {
    var conflicto = false;
    final ds = crear(
      (_) => conflicto
          ? http.Response(
              jsonEncode({
                'codigo': 'CONFLICTO',
                'mensaje': 'El correo ya está registrado',
              }),
              409,
            )
          : http.Response(
              jsonEncode({
                'usuario': {'id': 'u9', 'correo': 'n@uni.edu.co'},
                'invitacionEnviada': true,
              }),
              201,
            ),
    );
    const req = CrearUsuarioRequest(
      correo: 'n@uni.edu.co',
      nombre: 'N',
      apellido: 'M',
    );

    final r = await ds.crear(req);
    expect(r.usuarioId, 'u9');
    expect(r.invitacionEnviada, isTrue);

    conflicto = true;
    expect(
      () => ds.crear(req),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having(
              (e) => e.message,
              'message',
              'El correo ya está registrado',
            ),
      ),
    );
  });
}
