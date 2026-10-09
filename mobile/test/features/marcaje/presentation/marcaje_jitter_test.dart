// marcaje_jitter_test.dart — Jitter en refrescos automáticos (US-PLT-05 AC-05, R-05)
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/marcaje/data/repositories/marcaje_repository.dart';
import 'package:siaa_mobile/features/marcaje/data/services/marcaje_sync_trigger.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_bloc.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_event.dart';

class _MockRepo extends Mock implements MarcajeRepository {}

void main() {
  group('MarcajeBloc', () {
    late _MockRepo repo;
    late List<String> orden;
    late Completer<void> jitter;

    setUp(() {
      repo = _MockRepo();
      orden = [];
      jitter = Completer<void>();
      when(() => repo.obtenerSesionActiva()).thenAnswer((_) async {
        orden.add('consulta');
        return null;
      });
      when(() => repo.obtenerColaOffline()).thenAnswer((_) async => []);
    });

    MarcajeBloc crear() => MarcajeBloc(
          repository: repo,
          consentimientoOtorgado: () => true,
          esperarJitter: () {
            orden.add('jitter');
            return jitter.future;
          },
        );

    test('el refresco automático espera el jitter antes de consultar',
        () async {
      final bloc = crear();
      addTearDown(bloc.close);

      bloc.add(const CargarSesionActivaEvent(automatico: true));
      await Future<void>.delayed(Duration.zero);
      expect(orden, ['jitter'], reason: 'no consulta mientras dura el jitter');

      jitter.complete();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(orden, ['jitter', 'consulta']);
    });

    test('el refresco pedido por el usuario no espera', () async {
      final bloc = crear();
      addTearDown(bloc.close);

      bloc.add(const CargarSesionActivaEvent());
      await Future<void>.delayed(Duration.zero);
      expect(orden, ['consulta']);
    });
  });

  test('MarcajeSyncTrigger aplica jitter al volver la red, no al arrancar',
      () async {
    final red = StreamController<List<ConnectivityResult>>();
    final eventos = <String>[];
    final trigger = MarcajeSyncTrigger(
      sincronizar: () async => eventos.add('sync'),
      haySesion: () async => true,
      conectividad: red.stream,
      esperarJitter: () async => eventos.add('jitter'),
    )..iniciar(escucharCicloDeVida: false);
    await Future<void>.delayed(Duration.zero);
    expect(eventos, ['sync']);

    red.add([ConnectivityResult.mobile]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(eventos, ['sync', 'jitter', 'sync']);

    trigger.detener();
    await red.close();
  });
}
