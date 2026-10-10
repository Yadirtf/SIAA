import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaa_web/core/network/api_client.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/academico/data/models/cambio_sesion.dart';
import 'package:siaa_web/features/academico/data/models/sesion_model.dart';
import 'package:siaa_web/features/academico/data/sesiones_remote_datasource.dart';
import 'package:siaa_web/features/academico/presentation/bloc/sesiones_bloc.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/sesion_detalle_dialog.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/sesion_ops_dialogs.dart';

import 'academico_dialogs_test.dart' show FakeAcademicoRepository;

const _yaComenzo = ApiException(
  statusCode: 409,
  message: 'La sesión ya comenzó. Confirma para aplicar el cambio.',
  details: {'codigo': 'CONFIRMACION_REQUERIDA'},
);

const _sesion = SesionModel(
  id: 'ses-1',
  periodoId: 'per-1',
  asignacionId: 'asig-1',
  asignaturaId: 'as-1',
  grupoId: 'g-1',
  docenteIds: ['doc-1'],
  espacioId: 'esp-1',
  fecha: '2026-10-09',
  horaInicio: '08:00',
  horaFin: '10:00',
  inicioProgramado: '2026-10-09T13:00:00Z',
  finProgramado: '2026-10-09T15:00:00Z',
  estado: 'PROGRAMADA',
  asignaturaNombre: 'Cálculo I',
  grupoNumero: '01',
);

/// Pide confirmación mientras no llegue `confirmar` y registra los envíos.
class _RepoSesiones extends FakeAcademicoRepository {
  final reprogramaciones = <(ReprogramacionSesion, CambioSesion)>[];
  SesionModel detalle = _sesion;

  @override
  Future<SesionModel> reprogramarSesion({
    required String sesionId,
    required ReprogramacionSesion nueva,
    required CambioSesion cambio,
  }) async {
    reprogramaciones.add((nueva, cambio));
    if (!cambio.confirmar) throw _yaComenzo;
    return super.reprogramarSesion(
      sesionId: sesionId,
      nueva: nueva,
      cambio: cambio,
    );
  }

  @override
  Future<SesionModel> getSesion(String sesionId) async => detalle;
}

void main() {
  group('SesionesRemoteDataSource', () {
    late List<http.Request> peticiones;
    late String respuesta;

    SesionesRemoteDataSource crear() => SesionesRemoteDataSource(
      client: ApiClient(
        client: MockClient((req) async {
          peticiones.add(req);
          return http.Response(respuesta, 200);
        }),
      ),
    );

    setUp(() {
      peticiones = [];
      respuesta = jsonEncode({'id': 'ses-1', 'fecha': '2026-10-12'});
      SharedPreferences.setMockInitialValues({'siaa_access_token': 'tok'});
    });

    test('reasignar aula envía motivo y la confirmación', () async {
      await crear().reasignarAulaSesion(
        sesionId: 'ses-1',
        nuevoEspacioId: 'esp-2',
        cambio: const CambioSesion(
          motivo: 'Video beam dañado',
          confirmar: true,
        ),
      );
      final req = peticiones.single;
      expect(req.method, 'PUT');
      expect(req.url.path, endsWith('/sesiones/ses-1/aula'));
      expect(jsonDecode(req.body), {
        'nuevoEspacioId': 'esp-2',
        'motivo': 'Video beam dañado',
        'confirmar': true,
      });
    });

    test('reprogramar usa PATCH /sesiones/:id/reprogramar', () async {
      final s = await crear().reprogramarSesion(
        sesionId: 'ses-1',
        nueva: const ReprogramacionSesion(
          fecha: '2026-10-12',
          horaInicio: '14:00',
          horaFin: '16:00',
        ),
        cambio: const CambioSesion(motivo: 'Evento institucional'),
      );
      final req = peticiones.single;
      expect(req.method, 'PATCH');
      expect(req.url.path, endsWith('/sesiones/ses-1/reprogramar'));
      expect(jsonDecode(req.body), {
        'fecha': '2026-10-12',
        'horaInicio': '14:00',
        'horaFin': '16:00',
        'motivo': 'Evento institucional',
      });
      expect(s.fecha, '2026-10-12');
    });

    test('el detalle lee parámetros congelados y diferentes', () async {
      respuesta = jsonEncode({
        'id': 'ses-1',
        'parametrosCongelados': {'tolerancia_entrada_min': 15},
        'parametrosDiferentes': [
          {'clave': 'tolerancia_entrada_min', 'congelado': 15, 'actual': 10},
        ],
      });
      final s = await crear().getSesion('ses-1');
      expect(peticiones.single.url.path, endsWith('/sesiones/ses-1'));
      expect(s.parametrosCongelados, {'tolerancia_entrada_min': 15});
      expect(
        s.parametrosDiferentes.single,
        const DiferenciaParametro(
          clave: 'tolerancia_entrada_min',
          congelado: 15,
          actual: 10,
        ),
      );
    });
  });

  late _RepoSesiones repo;
  setUp(() => repo = _RepoSesiones());

  Future<void> abrir(WidgetTester tester, Widget dialogo) async {
    final bloc = SesionesBloc(repository: repo);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => BlocProvider.value(value: bloc, child: dialogo),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('reprogramar exige un motivo de al menos 5 caracteres', (
    tester,
  ) async {
    await abrir(tester, const ReprogramarSesionDialog(sesion: _sesion));
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.tap(find.text('Reprogramar'));
    await tester.pumpAndSettle();
    expect(find.text('Escriba al menos 5 caracteres'), findsOneWidget);
    expect(repo.reprogramaciones, isEmpty);
  });

  testWidgets('si la clase ya comenzó pide confirmar y reenvía', (
    tester,
  ) async {
    await abrir(tester, const ReprogramarSesionDialog(sesion: _sesion));
    await tester.enterText(find.byType(TextFormField), 'Evento institucional');
    await tester.tap(find.text('Reprogramar'));
    await tester.pumpAndSettle();

    expect(find.text('La clase ya comenzó'), findsOneWidget);
    expect(find.textContaining('Confirma para aplicar'), findsOneWidget);
    await tester.tap(find.text('Aplicar el cambio'));
    await tester.pumpAndSettle();

    expect(repo.reprogramaciones.map((r) => r.$2.confirmar), [false, true]);
    final (nueva, cambio) = repo.reprogramaciones.last;
    expect(nueva.fecha, '2026-10-09');
    expect(nueva.horaInicio, '08:00');
    expect(nueva.horaFin, '10:00');
    expect(cambio.motivo, 'Evento institucional');
    expect(find.byType(ReprogramarSesionDialog), findsNothing);
  });

  testWidgets('si no confirma, el formulario sigue abierto', (tester) async {
    await abrir(tester, const ReprogramarSesionDialog(sesion: _sesion));
    await tester.enterText(find.byType(TextFormField), 'Evento institucional');
    await tester.tap(find.text('Reprogramar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No, volver'));
    await tester.pumpAndSettle();
    expect(repo.reprogramaciones, hasLength(1));
    expect(find.byType(ReprogramarSesionDialog), findsOneWidget);
  });

  testWidgets('el detalle resalta los parámetros que ya cambiaron', (
    tester,
  ) async {
    repo.detalle = SesionModel.fromJson({
      'id': 'ses-1',
      'fecha': '2026-10-09',
      'horaInicio': '08:00',
      'horaFin': '10:00',
      'estado': 'PROGRAMADA',
      'parametrosCongelados': {
        'tolerancia_entrada_min': 15,
        'salida_obligatoria': 'OPCIONAL',
      },
      'parametrosDiferentes': [
        {
          'clave': 'salida_obligatoria',
          'congelado': 'OPCIONAL',
          'actual': 'OBLIGATORIO',
        },
      ],
    });
    await abrir(tester, SesionDetalleDialog(sesion: _sesion, repository: repo));

    expect(find.text('Parámetros congelados (RN-002)'), findsOneWidget);
    expect(find.text('Marcaje de salida'), findsOneWidget);
    expect(find.text('Opcional'), findsOneWidget);
    expect(find.text('Vigente hoy: Obligatorio'), findsOneWidget);
    expect(find.textContaining('1 parámetro cambió'), findsOneWidget);
  });
}
