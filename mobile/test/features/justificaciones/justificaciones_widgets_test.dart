import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/justificaciones/data/repositories/justificacion_repository.dart';
import 'package:siaa_mobile/features/justificaciones/data/services/soporte_picker_service.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/justificacion_model.dart';
import 'package:siaa_mobile/features/justificaciones/presentation/screens/justificacion_form_screen.dart';
import 'package:siaa_mobile/features/justificaciones/presentation/screens/mis_justificaciones_screen.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_historial_model.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/historial_item_card.dart';

class _MockRepo extends Mock implements JustificacionRepository {}

class _MockPicker extends Mock implements SoportePickerService {}

MarcajeHistorialItem _item(String resultado) => MarcajeHistorialItem(
      id: 'm1',
      sesionId: 's1',
      tipo: 'ENTRADA',
      resultado: resultado,
      origen: 'SISTEMA_AUTOMATICO',
      asignatura: 'Cálculo I',
      grupo: 'G1',
      espacioCodigo: 'A-101',
      timestampServidor: DateTime(2026, 9, 1, 8),
      timestampDispositivo: DateTime(2026, 9, 1, 8),
    );

void main() {
  testWidgets('HistorialItemCard muestra "Justificar" solo si aplica',
      (tester) async {
    var pulsado = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          HistorialItemCard(
            item: _item('AUSENTE'),
            onJustificar: () => pulsado = true,
          ),
          HistorialItemCard(item: _item('ACEPTADO'), onJustificar: () {}),
        ]),
      ),
    ));
    expect(find.text('Justificar'), findsOneWidget);
    await tester.tap(find.text('Justificar'));
    expect(pulsado, isTrue);
  });

  testWidgets('el formulario valida el tipo antes de radicar', (tester) async {
    final repo = _MockRepo();
    await tester.pumpWidget(MaterialApp(
      home: JustificacionFormScreen(
        sesionId: 's1',
        nombreSesion: 'Cálculo I',
        repository: repo,
        picker: _MockPicker(),
      ),
    ));
    expect(find.text('Incapacidad médica'), findsOneWidget);
    expect(find.text('Cámara'), findsOneWidget);
    await tester.ensureVisible(find.text('Radicar justificación'));
    await tester.tap(find.text('Radicar justificación'));
    await tester.pump();
    expect(find.text('Selecciona el tipo de justificación'), findsOneWidget);
  });

  testWidgets('Mis justificaciones lista con su estado', (tester) async {
    final repo = _MockRepo();
    when(() => repo.listar(
          estado: any(named: 'estado'),
          pagina: any(named: 'pagina'),
          limite: any(named: 'limite'),
        )).thenAnswer((_) async => const PaginaJustificaciones(items: [
          Justificacion(
            id: 'j1',
            sesionId: 's1',
            docenteId: 'd1',
            tipo: 'CALAMIDAD',
            descripcion: 'Calamidad doméstica urgente',
            estado: 'EN_REVISION',
            nombreSesion: 'Física II',
            fechaSesion: '2026-09-01',
          ),
        ], total: 1));
    await tester.pumpWidget(
        MaterialApp(home: MisJustificacionesScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(find.text('Física II'), findsOneWidget);
    expect(find.text('EN REVISIÓN'), findsOneWidget);
    expect(find.textContaining('01/09/2026'), findsOneWidget);
  });
}
