import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/geo/data/buscador_espacios.dart';
import 'package:siaa_web/features/geo/data/geo_remote_datasource.dart';

void main() {
  late List<Uri> peticiones;

  BuscadorEspaciosRemoto crear({bool bloquesFallan = false}) {
    final client = MockClient((req) async {
      peticiones.add(req.url);
      if (req.url.path.endsWith('/bloques')) {
        if (bloquesFallan) {
          return http.Response(jsonEncode({'mensaje': 'sin permiso'}), 403);
        }
        return http.Response(
          jsonEncode([
            {
              'id': 'b-1',
              'sedeId': 's-1',
              'codigo': 'BA',
              'nombre': 'Bloque A',
            },
          ]),
          200,
        );
      }
      return http.Response(
        jsonEncode([
          {
            'id': 'e-2',
            'sedeId': 's-1',
            'codigo': 'B-201',
            'nombre': 'Laboratorio',
            'tipo': 'LABORATORIO',
            'capacidad': 25,
            'estado': 'MANTENIMIENTO',
            'activo': true,
          },
          {
            'id': 'e-1',
            'sedeId': 's-1',
            'bloqueId': 'b-1',
            'piso': 1,
            'codigo': 'A-101',
            'nombre': 'Aula 101',
            'tipo': 'AULA',
            'capacidad': 40,
            'estado': 'ACTIVO',
            'activo': true,
          },
          {
            'id': 'e-3',
            'sedeId': 's-1',
            'codigo': 'X-000',
            'nombre': 'Aula cerrada',
            'estado': 'INACTIVO',
          },
        ]),
        200,
      );
    });
    return BuscadorEspaciosRemoto(
      geo: GeoRemoteDataSource(client: ApiClient(client: client)),
    );
  }

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  test('listar filtra por sede, omite inactivos y arma etiquetas', () async {
    final opciones = await crear().listar(sedeId: 's-1');

    expect(peticiones.first.queryParameters['sedeId'], 's-1');
    expect(opciones.map((o) => o.id), ['e-1', 'e-2']); // orden por código
    expect(opciones[0].etiqueta, 'A-101 · Aula 101 (Bloque A, piso 1)');
    expect(opciones[0].detalle, 'Aula · Capacidad 40');
    expect(opciones[1].etiqueta, 'B-201 · Laboratorio');
    expect(
      opciones[1].detalle,
      'Laboratorio · Capacidad 25 · En mantenimiento',
    );
  });

  test(
    'si los bloques fallan, lista los espacios sin nombre de bloque',
    () async {
      final opciones = await crear(bloquesFallan: true).listar();
      expect(peticiones.first.queryParameters.containsKey('sedeId'), isFalse);
      expect(opciones.first.etiqueta, 'A-101 · Aula 101 (piso 1)');
    },
  );
}
