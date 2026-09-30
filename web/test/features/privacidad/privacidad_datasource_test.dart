import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/privacidad/data/models/politica_privacidad_model.dart';
import 'package:siaa_web/features/privacidad/data/privacidad_remote_datasource.dart';

void main() {
  late List<http.Request> peticiones;

  PrivacidadRemoteDataSource crear(http.Response respuesta) {
    final client = MockClient((req) async {
      peticiones.add(req);
      return respuesta;
    });
    return PrivacidadRemoteDataSource(client: ApiClient(client: client));
  }

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  test('fromJson lee todos los campos y tolera ausentes', () {
    final p = PoliticaPrivacidadModel.fromJson(const {
      'version': '1.0',
      'contenido': '# Aviso',
      'actualizadaEn': '2026-09-30',
      'institucion': 'Universidad X',
      'contacto': 'privacidad@x.edu.co',
    });
    expect(p.version, '1.0');
    expect(p.contenido, '# Aviso');
    expect(p.actualizadaEn, '2026-09-30');
    expect(p.institucion, 'Universidad X');
    expect(p.contacto, 'privacidad@x.edu.co');

    final vacia = PoliticaPrivacidadModel.fromJson(const {'version': 2});
    expect(vacia.version, '2');
    expect(vacia.contenido, '');
    expect(vacia.contacto, '');
  });

  test('GET /privacidad/politica es público: no envía token', () async {
    final ds = crear(
      http.Response(
        jsonEncode({
          'version': '1.0',
          'contenido': 'Texto',
          'actualizadaEn': '2026-09-30',
          'institucion': 'U',
          'contacto': 'c@u.edu',
        }),
        200,
      ),
    );
    final p = await ds.obtenerPolitica();
    expect(p.version, '1.0');
    expect(peticiones.single.method, 'GET');
    expect(peticiones.single.url.path, endsWith('/privacidad/politica'));
    expect(peticiones.single.headers.containsKey('Authorization'), isFalse);
  });

  test('propaga el mensaje de error del backend', () async {
    final ds = crear(
      http.Response(jsonEncode({'codigo': 'X', 'mensaje': 'Caído'}), 500),
    );
    expect(
      ds.obtenerPolitica(),
      throwsA(isA<ApiException>().having((e) => e.message, 'm', 'Caído')),
    );
  });
}
