import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/justificaciones/data/justificaciones_remote_datasource.dart';
import 'package:siaa_web/features/justificaciones/data/models/justificaciones_filtro.dart';

void main() {
  late List<http.Request> peticiones;

  JustificacionesRemoteDataSource crear(
    http.Response Function(http.Request) responder,
  ) {
    final client = MockClient((req) async {
      peticiones.add(req);
      return responder(req);
    });
    return JustificacionesRemoteDataSource(client: ApiClient(client: client));
  }

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  test('listar envía filtros y lee X-Total-Count', () async {
    final ds = crear(
      (_) => http.Response(
        jsonEncode([
          {'id': 'j1', 'estado': 'RADICADA'},
        ]),
        200,
        headers: {'x-total-count': '80', 'content-type': 'application/json'},
      ),
    );
    final pagina = await ds.listar(
      const JustificacionesFiltro().copyWith(tipo: () => 'COMISION', pagina: 2),
    );
    final req = peticiones.single;
    expect(req.url.path, endsWith('/justificaciones'));
    expect(req.url.queryParameters['estado'], 'RADICADA');
    expect(req.url.queryParameters['tipo'], 'COMISION');
    expect(req.url.queryParameters['pagina'], '2');
    expect(req.headers['Authorization'], 'Bearer tok');
    expect(pagina.items.single.id, 'j1');
    expect(pagina.total, 80);
    expect(pagina.hayMas, isTrue);
  });

  test('revisar hace PATCH con estado y observaciones', () async {
    final ds = crear(
      (_) => http.Response(
        jsonEncode({'id': 'j1', 'estado': 'RECHAZADA'}),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    final j = await ds.revisar(
      'j1',
      estado: 'RECHAZADA',
      observaciones: 'Soporte ilegible',
    );
    final req = peticiones.single;
    expect(req.method, 'PATCH');
    expect(jsonDecode(req.body), {
      'estado': 'RECHAZADA',
      'observaciones': 'Soporte ilegible',
    });
    expect(j.estado, 'RECHAZADA');
  });

  test('revisar traduce 409 en ApiException con el mensaje', () async {
    final ds = crear(
      (_) => http.Response(
        jsonEncode({'codigo': 'CONFLICTO', 'mensaje': 'Ya fue decidida'}),
        409,
      ),
    );
    expect(
      () => ds.revisar('j1', estado: 'APROBADA'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.message, 'message', 'Ya fue decidida'),
      ),
    );
  });

  test('descargarSoporte devuelve bytes, MIME y nombre', () async {
    final ds = crear(
      (_) => http.Response.bytes(
        [1, 2, 3],
        200,
        headers: {
          'content-type': 'image/png',
          'content-disposition': 'inline; filename="foto.png"',
        },
      ),
    );
    final a = await ds.descargarSoporte('j1', 's9');
    expect(
      peticiones.single.url.path,
      endsWith('/justificaciones/j1/soportes/s9'),
    );
    expect(peticiones.single.headers['Authorization'], 'Bearer tok');
    expect(a.bytes, [1, 2, 3]);
    expect(a.esImagen, isTrue);
    expect(a.nombre, 'foto.png');
  });
}
