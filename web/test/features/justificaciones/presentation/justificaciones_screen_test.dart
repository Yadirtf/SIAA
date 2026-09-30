import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/justificaciones/data/models/adjunto_model.dart';
import 'package:siaa_web/features/justificaciones/data/models/justificacion_model.dart';
import 'package:siaa_web/features/justificaciones/domain/justificaciones_repository.dart';
import 'package:siaa_web/features/justificaciones/presentation/bloc/justificaciones_cubit.dart';
import 'package:siaa_web/features/justificaciones/presentation/screens/justificaciones_screen.dart';

import 'fake_justificaciones_repository.dart';

Future<FakeJustificacionesRepository> _montar(
  WidgetTester tester, {
  required bool puedeAprobar,
}) async {
  await tester.binding.setSurfaceSize(const Size(1600, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = FakeJustificacionesRepository()
    ..nombres = {'d1': 'Ana Pérez'}
    ..justificaciones = [
      const JustificacionModel(
        id: 'j1',
        sesionId: 's1',
        docenteId: 'd1',
        tipo: 'INCAPACIDAD',
        descripcion: 'Incapacidad médica de tres días',
        estado: 'RADICADA',
        fechaSesion: '2026-09-01',
        nombreSesion: 'Cálculo I - G1',
        adjuntos: [
          AdjuntoModel(
            id: 'a1',
            nombre: 'incapacidad.pdf',
            mime: 'application/pdf',
          ),
        ],
      ),
    ];
  await tester.pumpWidget(
    RepositoryProvider<JustificacionesRepository>.value(
      value: repo,
      child: BlocProvider(
        create: (_) => JustificacionesCubit(repository: repo),
        child: MaterialApp(
          home: Scaffold(
            body: JustificacionesScreen(puedeAprobar: puedeAprobar),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('lista con nombre del docente y detalle con acciones', (
    tester,
  ) async {
    await _montar(tester, puedeAprobar: true);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('Cálculo I - G1'), findsOneWidget);

    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de la justificación'), findsOneWidget);
    expect(find.text('incapacidad.pdf'), findsOneWidget);
    expect(find.text('Pasar a revisión'), findsOneWidget);
    expect(find.text('Aprobar'), findsOneWidget);

    await tester.tap(find.text('Rechazar'));
    await tester.pumpAndSettle();
    expect(find.text('Observaciones (obligatorias)'), findsOneWidget);
  });

  testWidgets('sin justificacion:aprobar no muestra acciones', (tester) async {
    await _montar(tester, puedeAprobar: false);
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle de la justificación'), findsOneWidget);
    expect(find.text('Aprobar'), findsNothing);
    expect(find.text('Rechazar'), findsNothing);
  });
}
