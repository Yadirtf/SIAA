// notificaciones_cubits_test.dart — Bandeja y preferencias (US-NOT-01/02)
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/notificaciones/data/notificaciones_remote_datasource.dart';
import 'package:siaa_mobile/features/notificaciones/domain/models/notificacion_model.dart';
import 'package:siaa_mobile/features/notificaciones/domain/models/preferencias_notificacion.dart';
import 'package:siaa_mobile/features/notificaciones/presentation/cubit/bandeja_cubit.dart';
import 'package:siaa_mobile/features/notificaciones/presentation/cubit/bandeja_state.dart';
import 'package:siaa_mobile/features/notificaciones/presentation/cubit/preferencias_notificacion_cubit.dart';
import 'package:siaa_mobile/features/notificaciones/presentation/screens/preferencias_notificacion_screen.dart';

class MockRemote extends Mock implements NotificacionesRemoteDataSource {}

final prefs = PreferenciasNotificacion.fromJson(const {
  'recordatorioSesion': true,
  'cierreVentana': true,
  'resultadoJustificacion': true,
  'cambioHorario': true,
  'obligatorias': ['cambioHorario'],
});

void main() {
  late MockRemote remote;

  setUpAll(() => registerFallbackValue(prefs));
  setUp(() => remote = MockRemote());

  group('BandejaCubit', () {
    const n1 = NotificacionModel(
      id: 'n1',
      tipo: 'CIERRE_VENTANA',
      titulo: 'Cierra la ventana',
      cuerpo: 'Quedan 5 minutos',
      datos: {'ruta': '/marcaje', 'sesionId': 's1'},
    );

    blocTest<BandejaCubit, BandejaState>(
      'abrir marca como leída y devuelve el destino',
      build: () {
        when(() => remote.listar()).thenAnswer((_) async => [n1]);
        when(() => remote.marcarLeida('n1')).thenAnswer((_) async {});
        return BandejaCubit(remote: remote);
      },
      act: (c) async {
        await c.cargar();
        expect(c.state.noLeidas, 1);
        final d = await c.abrir(c.state.items.first);
        expect(d?.sesionId, 's1');
      },
      verify: (c) {
        expect(c.state.noLeidas, 0);
        verify(() => remote.marcarLeida('n1')).called(1);
      },
    );
  });

  group('PreferenciasNotificacionCubit', () {
    blocTest<PreferenciasNotificacionCubit, PreferenciasNotificacionState>(
      'no envía cambios de una preferencia obligatoria',
      build: () => PreferenciasNotificacionCubit(remote: remote),
      seed: () => PreferenciasNotificacionState(preferencias: prefs),
      act: (c) => c.cambiar('cambioHorario', false),
      expect: () => [],
      verify: (_) => verifyNever(() => remote.guardarPreferencias(any())),
    );

    blocTest<PreferenciasNotificacionCubit, PreferenciasNotificacionState>(
      'revierte si el PUT falla',
      build: () {
        when(() => remote.guardarPreferencias(any()))
            .thenThrow(Exception('red'));
        return PreferenciasNotificacionCubit(remote: remote);
      },
      seed: () => PreferenciasNotificacionState(preferencias: prefs),
      act: (c) => c.cambiar('cierreVentana', false),
      verify: (c) {
        expect(c.state.preferencias?.valor('cierreVentana'), isTrue);
        expect(c.state.error, isNotNull);
      },
    );
  });

  testWidgets('pantalla: la obligatoria se muestra deshabilitada',
      (tester) async {
    when(() => remote.obtenerPreferencias()).thenAnswer((_) async => prefs);
    await tester.pumpWidget(MaterialApp(
      home: PreferenciasNotificacionScreen(
        cubit: PreferenciasNotificacionCubit(remote: remote),
      ),
    ));
    await tester.pumpAndSettle();

    final obligatoria = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('pref-cambioHorario')));
    expect(obligatoria.onChanged, isNull);
    expect(obligatoria.value, isTrue);
    expect(find.text('Obligatoria institucional'), findsOneWidget);
    final opcional = tester.widget<SwitchListTile>(
        find.byKey(const ValueKey('pref-cierreVentana')));
    expect(opcional.onChanged, isNotNull);
  });
}
