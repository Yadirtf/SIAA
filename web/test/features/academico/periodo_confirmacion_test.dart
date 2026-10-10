import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/edicion_remote_datasource.dart';
import 'package:siaa_web/features/academico/data/academico_remote_datasource.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/academico/presentation/bloc/academico_bloc.dart';
import 'package:siaa_web/features/academico/presentation/edicion/editores_academicos.dart';

import '../../helpers/fake_edicion.dart';
import 'academico_dialogs_test.dart' show FakeAcademicoRepository;

/// Rechaza con CONFIRMACION_REQUERIDA mientras no llegue la confirmación.
class _EdicionSolapada extends FakeEdicion {
  @override
  Future<Map<String, dynamic>> actualizar(
    String url,
    Map<String, dynamic> cuerpo, {
    bool parcial = false,
  }) async {
    llamadas.add((url, cuerpo, parcial));
    if (cuerpo['confirmarSolapamiento'] != true) {
      throw const ApiException(
        statusCode: 409,
        message:
            'Ya hay un periodo activo (2026-1) con fechas que se cruzan en '
            'esta sede. Confirma para activarlo de todos modos.',
        details: {'codigo': 'CONFIRMACION_REQUERIDA'},
      );
    }
    return const {};
  }
}

const _periodo = PeriodoModel(
  id: 'per-2',
  codigo: '2026-2',
  nombre: 'Segundo semestre',
  fechaInicio: '2026-06-01',
  fechaFin: '2026-12-15',
  estado: 'ACTIVO',
);

void main() {
  test('crear periodo envía confirmarSolapamiento solo si se pide', () async {
    SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
    final cuerpos = <Map<String, dynamic>>[];
    final ds = AcademicoRemoteDataSource(
      client: ApiClient(
        client: MockClient((req) async {
          cuerpos.add(jsonDecode(req.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode({
              'id': 'p1',
              'advertencias': ['El periodo dura menos de 8 semanas'],
            }),
            201,
          );
        }),
      ),
    );
    Future<PeriodoModel> crear(bool confirmar) => ds.createPeriodo(
      codigo: '2026-2',
      nombre: 'Segundo',
      fechaInicio: '2026-06-01',
      fechaFin: '2026-07-01',
      estado: 'ACTIVO',
      confirmarSolapamiento: confirmar,
    );
    await crear(false);
    final creado = await crear(true);
    expect(cuerpos[0].containsKey('confirmarSolapamiento'), isFalse);
    expect(cuerpos[1]['confirmarSolapamiento'], isTrue);
    expect(creado.advertencias, ['El periodo dura menos de 8 semanas']);
  });

  late _EdicionSolapada edicion;
  setUp(() => edicion = _EdicionSolapada());

  Future<void> abrir(WidgetTester tester) async {
    final bloc = AcademicoBloc(repository: FakeAcademicoRepository());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      RepositoryProvider<EdicionRemoteDataSource>.value(
        value: edicion,
        child: BlocProvider.value(
          value: bloc,
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => editarPeriodo(ctx, _periodo),
                child: const Text('Editar'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    // El indicador de guardado sigue girando detrás de la pregunta.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('al activar un periodo solapado pide confirmar y reenvía', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.text('El periodo se cruza con otro activo'), findsOneWidget);
    await tester.tap(find.text('Activarlo de todos modos'));
    await tester.pumpAndSettle();

    expect(edicion.llamadas, hasLength(2));
    expect(edicion.llamadas.last.$2['confirmarSolapamiento'], isTrue);
    expect(edicion.llamadas.last.$2['estado'], 'ACTIVO');
    expect(find.text('Editar periodo académico'), findsNothing);
  });

  testWidgets('si no confirma, el formulario sigue abierto sin error', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.text('No, volver'));
    await tester.pumpAndSettle();

    expect(edicion.llamadas, hasLength(1));
    expect(find.text('Editar periodo académico'), findsOneWidget);
    expect(find.text('No se pudo guardar'), findsNothing);
  });
}
