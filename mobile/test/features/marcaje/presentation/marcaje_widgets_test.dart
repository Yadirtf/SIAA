// marcaje_widgets_test.dart — Pruebas de widgets atómicos de marcaje
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_result_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_state.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/one_touch_button.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/rejection_dialog.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/sesion_card.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/sync_status_bar.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/traffic_light_badge.dart';

void main() {
  group('TrafficLightBadge (SRS §9.1)', () {
    testWidgets('renderiza texto adecuado para cada estado del semáforo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightBadge(semaforo: SemaforoMarcaje.listo, precision: 12.3),
          ),
        ),
      );

      expect(find.text('Listo para marcar (±12.3m)'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightBadge(semaforo: SemaforoMarcaje.fueraDeAula),
          ),
        ),
      );

      expect(find.text('Ubicación fuera del aula'), findsOneWidget);
    });
  });

  group('OneTouchButton (US-MAR-01, US-MAR-05)', () {
    testWidgets('se deshabilita y no dispara onTap cuando isSubmitting es true', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneTouchButton(
              onPressed: () => tapCount++,
              isSubmitting: true,
              isEnabled: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(OneTouchButton));
      await tester.pump();

      expect(tapCount, equals(0));
    });

    testWidgets('dispara callback cuando está habilitado y no está enviando', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OneTouchButton(
              onPressed: () => tapCount++,
              isSubmitting: false,
              isEnabled: true,
              label: 'MARCAR ENTRADA',
            ),
          ),
        ),
      );

      expect(find.text('MARCAR ENTRADA'), findsOneWidget);
      await tester.tap(find.byType(OneTouchButton));
      await tester.pump();

      expect(tapCount, equals(1));
    });
  });

  group('SesionCard (US-MAR-01)', () {
    testWidgets('muestra información de asignatura y aula', (tester) async {
      final sesion = SesionActivaModel(
        id: 's-1',
        asignatura: 'Estructuras de Datos',
        grupo: 'A1',
        espacio: const EspacioInfo(id: 'e-1', codigo: 'B-104', nombre: 'Auditorio B'),
        inicioProgramado: DateTime(2026, 9, 25, 10, 0),
        finProgramado: DateTime(2026, 9, 25, 12, 0),
        modalidad: 'PRESENCIAL',
        ventana: VentanaInfo(
          abreEn: DateTime(2026, 9, 25, 9, 45),
          cierraEn: DateTime(2026, 9, 25, 10, 15),
          estado: 'ABIERTA',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SesionCard(sesion: sesion),
          ),
        ),
      );

      expect(find.text('Estructuras de Datos'), findsOneWidget);
      expect(find.text('Grupo A1'), findsOneWidget);
      expect(find.text('B-104 — Auditorio B'), findsOneWidget);
    });
  });

  group('SyncStatusBar (US-MAR-11)', () {
    testWidgets('se oculta si count es 0 y se muestra si count > 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusBar(count: 0, onSyncPressed: () {}),
          ),
        ),
      );

      expect(find.textContaining('pendiente(s)'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusBar(count: 3, onSyncPressed: () {}),
          ),
        ),
      );

      expect(find.text('3 marcaje(s) local(es) pendiente(s)'), findsOneWidget);
      expect(find.text('Sincronizar'), findsOneWidget);
    });
  });

  group('RejectionDialog (US-MAR-06)', () {
    testWidgets('renderiza métricas de distancia y botón de reintento', (tester) async {
      const res = MarcajeResultModel(
        resultado: 'RECHAZADO',
        motivoRechazo: 'FUERA_DE_POLIGONO',
        mensaje: 'Estás a 35.8 metros del aula',
        distanciaMetros: 35.8,
        permiteReintento: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RejectionDialog(resultado: res),
          ),
        ),
      );

      expect(find.text('Marcaje No Registrado'), findsOneWidget);
      expect(find.text('Estás a 35.8 metros del aula'), findsOneWidget);
      expect(find.text('35.8 metros'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
