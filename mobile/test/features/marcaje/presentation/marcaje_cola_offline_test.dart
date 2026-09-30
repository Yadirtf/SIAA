// marcaje_cola_offline_test.dart — Estado de la cola offline en BLoC, UI y disparadores (US-MAR-11)
import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/marcaje/data/repositories/marcaje_repository.dart';
import 'package:siaa_mobile/features/marcaje/data/services/marcaje_sync_trigger.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_request_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_result_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/offline_marcaje_item.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/resumen_sincronizacion.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_bloc.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_event.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_state.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/cola_offline_panel.dart';

class MockMarcajeRepository extends Mock implements MarcajeRepository {}

OfflineMarcajeItem itemEn(String id, EstadoSincronizacion estado) =>
    OfflineMarcajeItem(
      localId: id,
      request: MarcajeRequestModel(
        sesionId: 'ses-$id',
        tipo: 'ENTRADA',
        latitud: 4.6,
        longitud: -74.06,
        precisionMetros: 8,
        timestampDispositivo: DateTime(2026, 9, 25, 7, 5),
        dispositivoId: 'dev',
        versionApp: '1.0.0',
      ),
      creadoEn: DateTime(2026, 9, 25, 7, 5),
      estado: estado,
      errorMensaje: 'Sin conexión con el servidor',
      resultadoServidor: estado == EstadoSincronizacion.rechazado
          ? const MarcajeResultModel(
              resultado: 'RECHAZADO_FUERA_DE_HORARIO',
              mensaje: 'Marcaje fuera de la ventana')
          : null,
    );

void main() {
  late MockMarcajeRepository repo;
  final cola = [
    itemEn('p', EstadoSincronizacion.pendiente),
    itemEn('r', EstadoSincronizacion.rechazado),
    itemEn('f', EstadoSincronizacion.fallido),
  ];

  setUp(() {
    repo = MockMarcajeRepository();
    when(() => repo.obtenerColaOffline()).thenAnswer((_) async => cola);
  });

  blocTest<MarcajeBloc, MarcajeState>(
    'SincronizarOfflineEvent expone pendientes, rechazados y fallidos',
    build: () {
      when(() => repo.sincronizarMarcajesOffline())
          .thenAnswer((_) async => ResumenSincronizacion.vacio);
      return MarcajeBloc(repository: repo);
    },
    act: (b) => b.add(const SincronizarOfflineEvent()),
    expect: () => [
      isA<MarcajeState>()
          .having((s) => s.colaOfflineCount, 'pendientes', 1)
          .having((s) => s.colaRechazados.single.localId, 'rechazado', 'r')
          .having((s) => s.colaFallidos.single.localId, 'fallido', 'f'),
    ],
  );

  blocTest<MarcajeBloc, MarcajeState>(
    'ReintentarMarcajeOfflineEvent reinicia el item y lanza sincronización',
    build: () {
      when(() => repo.reintentarMarcajeOffline(any())).thenAnswer((_) async {});
      when(() => repo.sincronizarMarcajesOffline())
          .thenAnswer((_) async => ResumenSincronizacion.vacio);
      return MarcajeBloc(repository: repo);
    },
    act: (b) => b.add(const ReintentarMarcajeOfflineEvent('f')),
    verify: (_) {
      verify(() => repo.reintentarMarcajeOffline('f')).called(1);
      verify(() => repo.sincronizarMarcajesOffline()).called(1);
    },
  );

  testWidgets('ColaOfflinePanel muestra mensaje del rechazo y reintento manual',
      (tester) async {
    OfflineMarcajeItem? reintentado;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ColaOfflinePanel(
          rechazados: [cola[1]],
          fallidos: [cola[2]],
          onJustificar: (_) {},
          onReintentar: (it) => reintentado = it,
        ),
      ),
    ));

    expect(find.text('Marcaje fuera de la ventana'), findsOneWidget);
    expect(find.text('Justificar'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(reintentado?.localId, 'f');
  });

  test('MarcajeSyncTrigger sincroniza al arrancar y al volver la red',
      () async {
    final red = StreamController<List<ConnectivityResult>>();
    var llamadas = 0;
    final trigger = MarcajeSyncTrigger(
      sincronizar: () async => llamadas++,
      haySesion: () async => true,
      conectividad: red.stream,
    )..iniciar(escucharCicloDeVida: false);
    await Future<void>.delayed(Duration.zero);
    expect(llamadas, 1);

    red.add([ConnectivityResult.none]);
    await Future<void>.delayed(Duration.zero);
    expect(llamadas, 1);
    red.add([ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    expect(llamadas, 2);

    trigger.detener();
    await red.close();
  });
}
