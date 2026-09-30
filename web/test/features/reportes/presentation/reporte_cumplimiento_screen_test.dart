import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/reportes/data/models/fila_cumplimiento_model.dart';
import 'package:siaa_web/features/reportes/data/models/reporte_cumplimiento_model.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/catalogo_reporte_cubit.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/reporte_cumplimiento_cubit.dart';
import 'package:siaa_web/features/reportes/presentation/screens/reporte_cumplimiento_screen.dart';

import 'fake_reportes_repository.dart';

Future<void> _montar(WidgetTester tester, {required bool exportar}) async {
  await tester.binding.setSurfaceSize(const Size(1800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = FakeReportesRepository()
    ..reporte = const ReporteCumplimientoModel(
      docentes: [
        FilaCumplimientoModel(
          docenteId: 'd1',
          nombre: 'Ana Pérez',
          sesiones: 4,
          porcentajeCumplimiento: 87.5,
        ),
      ],
      totales: FilaCumplimientoModel(
        sesiones: 4,
        tardanzas: 2,
        porcentajeCumplimiento: 87.5,
      ),
      falsosRechazos: 1,
    );
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CatalogoReporteCubit(repository: repo)),
        BlocProvider(
          create: (_) =>
              ReporteCumplimientoCubit(repository: repo, guardar: (_, __) {}),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ReporteCumplimientoScreen(puedeExportar: exportar),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('consulta por periodo y muestra indicadores y totales', (
    tester,
  ) async {
    await _montar(tester, exportar: true);
    expect(find.text('Exportar XLSX'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);

    await tester.tap(find.text('Sin periodo (usar fechas)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Periodo 2026-2').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('TOTALES'), findsOneWidget);
    expect(find.text('Falsos rechazos'), findsOneWidget);
    expect(find.text('87.5 %'), findsWidgets);
  });

  testWidgets('sin reporte:exportar no muestra los botones', (tester) async {
    await _montar(tester, exportar: false);
    expect(find.text('Exportar XLSX'), findsNothing);
    expect(find.text('Exportar PDF'), findsNothing);
  });
}
