import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/features/academico/data/generacion_sesiones_remote_datasource.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/academico/data/models/informe_generacion_model.dart';
import 'package:siaa_web/features/academico/presentation/widgets/generar_sesiones_boton.dart';

void main() {
  late List<http.Request> peticiones;

  GeneracionSesionesRemoteDataSource crear(http.Response respuesta) {
    final client = MockClient((req) async {
      peticiones.add(req);
      return respuesta;
    });
    return GeneracionSesionesRemoteDataSource(
      client: ApiClient(client: client),
    );
  }

  final informe = {
    'periodoId': 'p1',
    'asignacionesProcesadas': 2,
    'sesionesGeneradas': 34,
    'sesionesOmitidasIdempotencia': 3,
    'fechasExcluidas': [
      {'fecha': '2026-10-12', 'motivo': 'Festivo (FESTIVO)'},
    ],
    'asignacionesOmitidas': [],
    'mensaje': 'ok',
  };

  setUp(() {
    peticiones = [];
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
  });

  test('llama POST /periodos/:id/generar-sesiones y lee el informe', () async {
    final ds = crear(http.Response(jsonEncode(informe), 200));
    final r = await ds.generar('p1');
    expect(peticiones.single.method, 'POST');
    expect(
      peticiones.single.url.path,
      endsWith('/periodos/p1/generar-sesiones'),
    );
    expect(r.sesionesGeneradas, 34);
    expect(r.fechasExcluidas.single, contains('2026-10-12'));
  });

  PeriodoModel periodo(String estado) => PeriodoModel.fromJson({
    'id': 'p1',
    'codigo': '2026-2',
    'nombre': 'Segundo semestre',
    'fechaInicio': '2026-08-01',
    'fechaFin': '2026-12-15',
    'estado': estado,
  });

  testWidgets('confirma, genera y muestra el informe', (tester) async {
    final ds = _DataSourceFijo(InformeGeneracionModel.fromJson(informe));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenerarSesionesBoton(
            periodo: periodo('ACTIVO'),
            dataSource: ds,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Generar sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar'));
    await tester.pumpAndSettle();
    expect(find.text('Sesiones generadas'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
    expect(ds.llamadas, ['p1']);
  });

  testWidgets('no se muestra en un periodo cerrado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: GenerarSesionesBoton(periodo: periodo('CERRADO'))),
      ),
    );
    expect(find.text('Generar sesiones'), findsNothing);
  });
}

class _DataSourceFijo extends GeneracionSesionesRemoteDataSource {
  final InformeGeneracionModel informe;
  final llamadas = <String>[];

  _DataSourceFijo(this.informe);

  @override
  Future<InformeGeneracionModel> generar(String periodoId) async {
    llamadas.add(periodoId);
    return informe;
  }
}
