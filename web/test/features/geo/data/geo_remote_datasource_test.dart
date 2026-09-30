import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/errores_campo.dart';
import 'package:siaa_web/features/geo/data/geo_remote_datasource.dart';
import 'package:siaa_web/features/geo/data/models/geo_models.dart';

void main() {
  late List<http.Request> peticiones;

  GeoRemoteDataSource crear(http.Response Function(http.Request) responder) {
    final client = MockClient((req) async {
      peticiones.add(req);
      return responder(req);
    });
    return GeoRemoteDataSource(client: ApiClient(client: client));
  }

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  test('actualizarVerificacion hace PUT y devuelve el espacio', () async {
    final ds = crear(
      (_) => http.Response(
        jsonEncode({
          'id': 'e1',
          'codigo': 'AUL-101',
          'nombre': 'Aula 101',
          'verificacionComplementaria': {
            'wifiBssids': ['a4:2b:8c:11:02:9f'],
            'qrCodigo': 'SIAA-AUL-101-ABC123',
          },
        }),
        200,
      ),
    );

    final espacio = await ds.actualizarVerificacion(
      'e1',
      const VerificacionEspacioModel(
        wifiBssids: ['A4-2B-8C-11-02-9F'],
        qrCodigo: 'SIAA-AUL-101-ABC123',
      ),
    );

    final req = peticiones.single;
    expect(req.method, 'PUT');
    expect(req.url.path, endsWith('/espacios/e1/verificacion'));
    expect(req.headers['Authorization'], 'Bearer tok');
    expect(jsonDecode(req.body), {
      'wifiBssids': ['A4-2B-8C-11-02-9F'],
      'bleUuid': '',
      'qrCodigo': 'SIAA-AUL-101-ABC123',
    });
    expect(espacio.verificacionComplementaria!.metodos, ['WIFI', 'QR']);
  });

  test('un 422 conserva los detalles por campo', () async {
    final ds = crear(
      (_) => http.Response(
        jsonEncode({
          'codigo': 'VALIDACION',
          'mensaje': 'Verificación complementaria inválida',
          'detalles': [
            {'campo': 'qrCodigo', 'error': 'mínimo 6 caracteres'},
          ],
        }),
        422,
      ),
    );

    try {
      await ds.actualizarVerificacion(
        'e1',
        const VerificacionEspacioModel(qrCodigo: 'ABC'),
      );
      fail('debía lanzar ApiException');
    } on ApiException catch (e) {
      expect(e.statusCode, 422);
      expect(e.message, 'Verificación complementaria inválida');
      expect(erroresDeCampo(e), {
        'qrCodigo': ['mínimo 6 caracteres'],
      });
    }
  });
}
