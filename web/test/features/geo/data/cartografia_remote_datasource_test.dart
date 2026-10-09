import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/geo/data/cartografia_remote_datasource.dart';
import 'package:siaa_web/features/geo/presentation/cartografia/importar_cartografia_cubit.dart';

const _preview = {
  'formato': 'kml',
  'totalElementos': 2,
  'validos': 1,
  'invalidos': 1,
  'elementos': [
    {
      'indice': 1,
      'codigo': 'KML-1',
      'nombre': 'Sala',
      'tipo': 'AULA',
      'valido': true,
      'coordenadasInvertidas': true,
      'vertices': [
        [-76.1, 1.1],
      ],
      'advertencias': ['Se detectó orden [latitud, longitud] invertido'],
    },
    {
      'indice': 2,
      'codigo': 'IMP-2',
      'nombre': 'Poste',
      'tipo': 'AULA',
      'valido': false,
      'coordenadasInvertidas': false,
      'errores': ['La geometría debe ser de tipo Polygon'],
    },
  ],
};

void main() {
  late List<http.BaseRequest> peticiones;

  CartografiaRemoteDataSource crear(http.Response Function() responder) =>
      CartografiaRemoteDataSource(
        client: ApiClient(
          client: MockClient((req) async {
            peticiones.add(req);
            return responder();
          }),
        ),
      );

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  test('exportar pide el formato KML de la sede', () async {
    final ds = crear(
      () => http.Response(
        '<kml/>',
        200,
        headers: {'content-type': 'application/vnd.google-earth.kml+xml'},
      ),
    );
    final archivo = await ds.exportar(sedeId: 's1', formato: 'kml');
    expect(peticiones.single.url.path, endsWith('/espacios/exportar'));
    expect(peticiones.single.url.queryParameters, {
      'sedeId': 's1',
      'formato': 'kml',
    });
    expect(archivo.mime, 'application/vnd.google-earth.kml+xml');
  });

  test('el cubit previsualiza KML y confirma solo los válidos', () async {
    var paso = 0;
    final cubit = ImportarCartografiaCubit(
      dataSource: crear(() {
        paso++;
        return paso == 1
            ? http.Response(jsonEncode(_preview), 200)
            : http.Response(
                jsonEncode({
                  'totalImportados': 1,
                  'omitidos': [
                    {'codigo': 'X', 'motivo': 'ya existe'},
                  ],
                }),
                201,
              );
      }),
    );
    addTearDown(cubit.close);

    await cubit.previsualizar(utf8.encode('<kml/>'), 'aulas.kml');
    expect(cubit.state.paso, PasoImportacionCartografia.previa);
    expect(cubit.state.previa!.formato, 'kml');
    expect(cubit.state.previa!.elementos.first.coordenadasInvertidas, isTrue);
    expect(peticiones.first.url.path, endsWith('/espacios/importar/preview'));
    final subida = peticiones.first as http.Request;
    expect(subida.headers['content-type'], startsWith('multipart/form-data'));
    expect(subida.body, contains('filename="aulas.kml"'));

    await cubit.confirmar(sedeId: 's1', piso: 2);
    final body = jsonDecode(
      (peticiones.last as http.Request).body,
    ) as Map<String, dynamic>;
    expect(body['sedeId'], 's1');
    expect(body['piso'], 2);
    expect((body['elementos'] as List).single['codigo'], 'KML-1');
    expect(cubit.state.paso, PasoImportacionCartografia.completada);
    expect(cubit.state.resultado!.omitidos.single, 'X: ya existe');
  });

  test('un archivo ilegible muestra el mensaje del backend', () async {
    final cubit = ImportarCartografiaCubit(
      dataSource: crear(
        () => http.Response(
          jsonEncode({
            'codigo': 'VALIDACION',
            'mensaje': 'El archivo no es un KML válido',
          }),
          422,
        ),
      ),
    );
    addTearDown(cubit.close);
    await cubit.previsualizar([1, 2], 'roto.kml');
    expect(cubit.state.error, 'El archivo no es un KML válido');
    expect(cubit.state.puedeConfirmar, isFalse);
  });
}
