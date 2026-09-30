// marcajes_widgets_test.dart — Pruebas de widgets de administración de marcajes en web
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/marcajes/domain/models/marcaje_admin_model.dart';
import 'package:siaa_web/features/marcajes/presentation/widgets/ajuste_marcaje_dialog.dart';
import 'package:siaa_web/features/marcajes/presentation/widgets/marcajes_data_table.dart';
import 'package:siaa_web/features/marcajes/presentation/widgets/marcajes_filter_bar.dart';

void main() {
  group('MarcajesDataTable (US-MAR-09, US-MAR-10)', () {
    testWidgets('renderiza datos de usuario y badge de anomalía cuando corresponde', (tester) async {
      final marcajes = [
        MarcajeAdminModel(
          id: 'mar-1',
          sesionId: 'ses-101',
          usuarioId: 'docente-pedro',
          asignatura: 'Física I',
          tipo: 'ENTRADA',
          resultado: 'RECHAZADO',
          origen: 'MOVIL_ONLINE',
          timestampServidor: DateTime(2026, 9, 25, 7, 5),
          timestampDispositivo: DateTime(2026, 9, 25, 7, 5),
          mockLocation: true,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarcajesDataTable(
              marcajes: marcajes,
              onSeleccionar: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('docente-pedro'), findsOneWidget);
      expect(find.text('Física I'), findsOneWidget);
      expect(find.text('RECHAZADO'), findsOneWidget);
      expect(find.text('Mock GPS'), findsOneWidget);
      expect(find.text('Ajustar'), findsOneWidget);
    });
  });

  group('MarcajesFilterBar (US-MAR-09)', () {
    testWidgets('renderiza campos y dispara callback al presionar Filtrar', (tester) async {
      FiltrosMarcajeAdmin? filtrosCapturados;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarcajesFilterBar(
              onFiltrar: (f) => filtrosCapturados = f,
              onNuevoManual: () {},
            ),
          ),
        ),
      );

      expect(find.text('Usuario'), findsOneWidget);
      expect(find.text('Marcaje Manual'), findsOneWidget);

      await tester.tap(find.text('Filtrar'));
      await tester.pump();

      expect(filtrosCapturados, isNotNull);
    });
  });

  group('AjusteMarcajeDialog (US-MAR-09)', () {
    testWidgets('botón de aplicar ajuste se mantiene deshabilitado hasta ingresar 20 caracteres', (tester) async {
      final m = MarcajeAdminModel(
        id: 'mar-test',
        sesionId: 'ses-test',
        usuarioId: 'usr-test',
        tipo: 'ENTRADA',
        resultado: 'RECHAZADO',
        origen: 'MOVIL_ONLINE',
        timestampServidor: DateTime.now(),
        timestampDispositivo: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AjusteMarcajeDialog(
              marcaje: m,
              onConfirmar: ({required accion, required anulado, required motivo, nuevoResultado}) {},
            ),
          ),
        ),
      );

      // Verificamos que inicialmente muestra 0 / 20 mín y el botón no es clickeable
      expect(find.text('0 / 20 mín'), findsOneWidget);
      final boton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(boton.onPressed, isNull);

      // Escribimos motivo corto (10 caracteres)
      await tester.enterText(find.byType(TextField), 'Falla gps.');
      await tester.pump();
      expect(find.text('10 / 20 mín'), findsOneWidget);
      final botonAunInvalido = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(botonAunInvalido.onPressed, isNull);

      // Escribimos motivo válido (>= 20 caracteres)
      await tester.enterText(find.byType(TextField), 'Falla general del satélite GPS en campus norte.');
      await tester.pump();
      final botonHabilitado = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(botonHabilitado.onPressed, isNotNull);
    });
  });
}
