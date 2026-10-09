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
import 'package:siaa_web/features/academico/data/models/trabajo_model.dart';
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

  test(
    'modo asíncrono envía asincrono e incluirPasadas y lee el trabajo',
    () async {
      final ds = crear(
        http.Response(
          jsonEncode({'id': 't1', 'estado': 'EN_PROCESO', 'progreso': 0}),
          202,
        ),
      );
      final t = await ds.iniciarGeneracion('p1', incluirPasadas: true);
      expect(t.id, 't1');
      expect(t.terminado, isFalse);
      expect(jsonDecode(peticiones.single.body), {
        'asincrono': true,
        'incluirPasadas': true,
      });
    },
  );

  test('consulta GET /trabajos/:id y lee el informe del resultado', () async {
    final ds = crear(
      http.Response(
        jsonEncode({
          'id': 't1',
          'estado': 'COMPLETADO',
          'progreso': 100,
          'resultado': {...informe, 'sesionesPasadasOmitidas': 5},
        }),
        200,
      ),
    );
    final t = await ds.consultarTrabajo('t1');
    expect(peticiones.single.method, 'GET');
    expect(peticiones.single.url.path, endsWith('/trabajos/t1'));
    expect(t.terminado, isTrue);
    final r = InformeGeneracionModel.fromJson(t.resultado!);
    expect(r.sesionesPasadasOmitidas, 5);
  });

  testWidgets('confirma, genera en segundo plano y muestra el informe', (
    tester,
  ) async {
    final ds = _DataSourceAsincrono([
      const TrabajoModel(id: 't1', progreso: 50),
      TrabajoModel(
        id: 't1',
        estado: TrabajoModel.completado,
        progreso: 100,
        resultado: {...informe, 'sesionesPasadasOmitidas': 7},
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenerarSesionesBoton(
            periodo: periodo('ACTIVO'),
            dataSource: ds,
            intervaloConsulta: Duration.zero,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Generar sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Incluir fechas pasadas'));
    await tester.pump();
    await tester.tap(find.text('Generar'));
    await tester.pumpAndSettle();
    expect(find.text('Sesiones generadas'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
    expect(find.text('Fechas pasadas no generadas'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(ds.inicios, [('p1', true)]);
    expect(ds.consultas, 2);
  });

  testWidgets('si el trabajo falla avisa con el error del servidor', (
    tester,
  ) async {
    final ds = _DataSourceAsincrono([
      const TrabajoModel(
        id: 't1',
        estado: TrabajoModel.fallido,
        error: 'Periodo cerrado',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GenerarSesionesBoton(
            periodo: periodo('ACTIVO'),
            dataSource: ds,
            intervaloConsulta: Duration.zero,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Generar sesiones'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Periodo cerrado'), findsOneWidget);
    expect(ds.inicios, [('p1', false)]);
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

/// Responde al inicio con un trabajo en proceso y, en cada consulta, con el
/// siguiente estado de [estados].
class _DataSourceAsincrono extends GeneracionSesionesRemoteDataSource {
  final List<TrabajoModel> estados;
  final inicios = <(String, bool)>[];
  int consultas = 0;

  _DataSourceAsincrono(this.estados);

  @override
  Future<TrabajoModel> iniciarGeneracion(
    String periodoId, {
    bool incluirPasadas = false,
  }) async {
    inicios.add((periodoId, incluirPasadas));
    return const TrabajoModel(id: 't1');
  }

  @override
  Future<TrabajoModel> consultarTrabajo(String trabajoId) async {
    final i = consultas < estados.length ? consultas : estados.length - 1;
    consultas++;
    return estados[i];
  }
}
