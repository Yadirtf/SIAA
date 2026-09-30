import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/academico/data/academico_remote_datasource.dart';
import 'package:siaa_web/features/geo/data/geo_remote_datasource.dart';
import 'package:siaa_web/features/parametros/data/opciones_ambito_datasource.dart';

void main() {
  late OpcionesAmbitoRemoto fuente;

  setUp(() {
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
    final client = ApiClient(
      client: MockClient((req) async {
        final ruta = req.url.path;
        final cuerpo = ruta.endsWith('/sedes')
            ? [
                {
                  'id': 's-1',
                  'codigo': 'CEN',
                  'nombre': 'Sede Centro',
                  'direccion': 'Cra 1 # 2-3',
                },
              ]
            : ruta.endsWith('/facultades')
            ? [
                {'id': 'f-1', 'codigo': 'ING', 'nombre': 'Ingeniería'},
              ]
            : ruta.endsWith('/bloques')
            ? [
                {
                  'id': 'b-1',
                  'sedeId': 's-1',
                  'codigo': 'BA',
                  'nombre': 'Bloque A',
                  'pisos': [1, 2],
                },
              ]
            : [];
        return http.Response(jsonEncode(cuerpo), 200);
      }),
    );
    fuente = OpcionesAmbitoRemoto(
      geo: GeoRemoteDataSource(client: client),
      academico: AcademicoRemoteDataSource(client: client),
    );
  });

  test('cada nivel se mapea a opciones legibles', () async {
    final sede = (await fuente.opciones('SEDE')).single;
    expect(sede.id, 's-1');
    expect(sede.etiqueta, 'CEN · Sede Centro');
    expect(sede.detalle, 'Cra 1 # 2-3');

    final facultad = (await fuente.opciones('FACULTAD')).single;
    expect(facultad.etiqueta, 'ING · Ingeniería');

    final bloque = (await fuente.opciones('BLOQUE')).single;
    expect(bloque.etiqueta, 'BA · Bloque A');
    expect(bloque.detalle, 'Pisos 1, 2');

    expect(await fuente.opciones('AULA'), isEmpty);
    expect(await fuente.opciones('GLOBAL'), isEmpty);
  });
}
