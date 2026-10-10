// derechos_test.dart — Copia de datos, rectificación y supresión del titular (US-LEG-02)
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/notificaciones/domain/models/destino_notificacion.dart';
import 'package:siaa_mobile/features/privacidad/data/derechos_remote_datasource.dart';
import 'package:siaa_mobile/features/privacidad/domain/models/canal_derechos.dart';
import 'package:siaa_mobile/features/privacidad/domain/models/solicitud_derecho.dart';
import 'package:siaa_mobile/features/privacidad/presentation/cubit/derechos_cubit.dart';
import 'package:siaa_mobile/features/privacidad/presentation/screens/derechos_screen.dart';

class MockDerechos extends Mock implements DerechosRemoteDataSource {}

const _canal = CanalDerechos(
  contacto: 'datos@uni.edu.co',
  plazos: [
    PlazoDerecho(
        tipo: 'RECTIFICACION',
        descripcion: 'Actualizar o rectificar datos inexactos',
        diasHabiles: 15,
        prorroga: 8,
        fundamento: 'Ley 1581 de 2012, art. 15'),
  ],
);

final _evaluacion = [
  ElementoSupresion.fromJson(const {
    'categoria': 'UBICACIONES_MARCAJE',
    'descripcion': 'Coordenadas GPS',
    'decision': 'ELIMINABLE',
    'fundamento': 'Principio de finalidad',
  }),
  ElementoSupresion.fromJson(const {
    'categoria': 'REGISTROS_ASISTENCIA',
    'descripcion': 'Registros de asistencia',
    'decision': 'CONSERVAR',
    'fundamento': 'Decreto 1377 de 2013, art. 9',
  }),
];

final _abierta = SolicitudDerecho.fromJson(const {
  'id': 's1',
  'tipo': 'RECTIFICACION',
  'estado': 'EN_TRAMITE',
  'cambios': {'apellido': 'Pérez Rojas'},
  'radicadaEn': '2026-10-01T15:00:00Z',
  'venceEn': '2026-10-22T04:59:59Z',
});

void main() {
  late MockDerechos remote;

  setUp(() {
    remote = MockDerechos();
    when(() => remote.canal()).thenAnswer((_) async => _canal);
    when(() => remote.misSolicitudes()).thenAnswer((_) async => [_abierta]);
    when(() => remote.evaluarSupresion()).thenAnswer((_) async => _evaluacion);
  });

  test('el modelo interpreta estado, plazo y evaluación', () {
    expect(_abierta.abierta, isTrue);
    expect(_abierta.estadoLegible, 'En trámite');
    expect(_abierta.venceEn, isNotNull);
    expect(_evaluacion.first.eliminable, isTrue);
    expect(_evaluacion.last.eliminable, isFalse);
  });

  test('descarga la copia y la guarda como archivo (AC-01)', () async {
    String? nombre;
    when(() => remote.descargarMisDatos()).thenAnswer(
        (_) async => Uint8List.fromList('{"titular":{}}'.codeUnits));
    final cubit = DerechosCubit(
      remote: remote,
      guardar: (n, bytes) async {
        nombre = n;
        return bytes.isNotEmpty;
      },
    );
    addTearDown(cubit.close);
    await cubit.descargarCopia();
    expect(nombre, 'mis-datos-siaa.json');
    expect(cubit.state.mensaje, contains('guardada'));
  });

  test('radicar agrega el caso y un error del servidor se muestra', () async {
    final cubit = DerechosCubit(remote: remote, guardar: (_, __) async => true);
    addTearDown(cubit.close);
    await cubit.cargar();
    expect(cubit.state.tieneAbierta('RECTIFICACION'), isTrue);
    expect(cubit.state.tieneAbierta('SUPRESION'), isFalse);

    final nueva = SolicitudDerecho.fromJson(const {
      'id': 's2',
      'tipo': 'SUPRESION',
      'estado': 'RADICADA',
    });
    when(() => remote.radicar(
          tipo: 'SUPRESION',
          descripcion: any(named: 'descripcion'),
          cambios: any(named: 'cambios'),
        )).thenAnswer((_) async => nueva);
    expect(
        await cubit.radicar(
            tipo: 'SUPRESION', descripcion: 'Suprimir mis ubicaciones'),
        isTrue);
    expect(cubit.state.solicitudes.first.id, 's2');

    when(() => remote.radicar(
          tipo: 'RECTIFICACION',
          descripcion: any(named: 'descripcion'),
          cambios: any(named: 'cambios'),
        )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/me/derechos/solicitudes'),
      response: Response(
        requestOptions: RequestOptions(path: '/me/derechos/solicitudes'),
        statusCode: 409,
        data: {'mensaje': 'Ya tiene una solicitud de RECTIFICACION en trámite'},
      ),
    ));
    expect(await cubit.radicar(tipo: 'RECTIFICACION', descripcion: 'Otra vez'),
        isFalse);
    expect(cubit.state.error, contains('en trámite'));
  });

  testWidgets('la pantalla muestra plazos, casos y la evaluación de supresión',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DerechosScreen(remote: remote, guardar: (_, __) async => true),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Descargar copia de mis datos'), findsOneWidget);
    expect(find.textContaining('15 días hábiles'), findsOneWidget);
    expect(find.text('Rectificación de datos'), findsOneWidget);
    expect(find.text('En trámite'), findsOneWidget);
    // Ya hay una rectificación abierta: el botón queda deshabilitado.
    final rect = tester.widget<OutlinedButton>(find.ancestor(
        of: find.text('Solicitar rectificación'),
        matching: find.byWidgetPredicate((w) => w is OutlinedButton)));
    expect(rect.onPressed, isNull);

    await tester.tap(find.text('Solicitar supresión'));
    await tester.pumpAndSettle();
    expect(find.text('Se eliminarán'), findsOneWidget);
    expect(find.text('Se conservarán por obligación legal'), findsOneWidget);
    expect(find.textContaining('Decreto 1377'), findsOneWidget);
    await tester.tap(find.text('Radicar'));
    await tester.pump();
    expect(find.textContaining('mínimo 10'), findsOneWidget);
  });

  test('los avisos de revisión y de derechos abren su pantalla', () {
    expect(
        DestinoNotificacion.desdeDatos(
            const {'ruta': '/justificaciones/revision'})?.rutaShell,
        '/shell/aprobar-justificaciones');
    expect(
        DestinoNotificacion.desdeDatos(const {'ruta': '/privacidad/derechos'})
            ?.rutaShell,
        '/shell/derechos');
  });
}
