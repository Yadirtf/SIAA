import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/theme/app_colors.dart';
import 'package:siaa_web/features/reportes/data/models/asistencia_grupo_model.dart';
import 'package:siaa_web/features/reportes/data/models/ocupacion_model.dart';
import 'package:siaa_web/features/reportes/data/models/tablero_model.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/asistencia_grupo_cubit.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/ocupacion_cubit.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/tablero_cubit.dart';
import 'package:siaa_web/features/reportes/presentation/screens/asistencia_estudiantil_screen.dart';
import 'package:siaa_web/features/reportes/presentation/screens/ocupacion_screen.dart';
import 'package:siaa_web/features/reportes/presentation/screens/tablero_screen.dart';

import 'fake_reportes_operativos_repository.dart';

Future<void> _montar<C extends Cubit<Object?>>(
  WidgetTester tester,
  C cubit,
  Widget pantalla,
) async {
  await tester.binding.setSurfaceSize(const Size(1800, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(cubit.close);
  await tester.pumpWidget(
    BlocProvider<C>.value(
      value: cubit,
      child: MaterialApp(home: Scaffold(body: pantalla)),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _elegir(WidgetTester tester, String abrir, String opcion) async {
  await tester.tap(find.text(abrir));
  await tester.pumpAndSettle();
  await tester.tap(find.text(opcion).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('asistencia: resalta a los estudiantes bajo el umbral', (
    tester,
  ) async {
    final repo = FakeReportesOperativosRepository()
      ..asistencia = const ReporteAsistenciaGrupoModel(
        grupoId: 'g1',
        umbral: 80,
        promedioGrupo: 50,
        estudiantesBajoUmbral: 1,
        estudiantes: [
          FilaEstudianteModel(
            estudianteId: 'e1',
            nombre: 'Ana',
            porcentaje: 100,
          ),
          FilaEstudianteModel(
            estudianteId: 'e2',
            nombre: 'Luis',
            porcentaje: 0,
            bajoUmbral: true,
          ),
        ],
      );
    final cubit = AsistenciaGrupoCubit(repository: repo);
    await _montar(tester, cubit, const AsistenciaEstudiantilScreen());

    await _elegir(tester, 'Periodo académico', 'Periodo 2026-2');
    await _elegir(tester, 'Grupo', 'Cálculo · Grupo 01');
    expect(repo.llamadas, ['grupos:p1', 'asistencia:g1']);
    expect(find.text('50.0 %'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);

    final tabla = tester.widget<DataTable>(find.byType(DataTable));
    final luis = tabla.rows.firstWhere(
      (r) => r.key == const ValueKey('estudiante-e2'),
    );
    final ana = tabla.rows.firstWhere(
      (r) => r.key == const ValueKey('estudiante-e1'),
    );
    expect(luis.color?.resolve({}), AppColors.statusDangerBg);
    expect(ana.color, isNull);
  });

  testWidgets('tablero: muestra indicadores y la sesión sin marcaje', (
    tester,
  ) async {
    final repo = FakeReportesOperativosRepository()
      ..tableroRespuesta = const TableroModel(
        fecha: '2026-10-09',
        sesionesDelDia: 7,
        sinMarcaje: [
          SesionSinMarcajeModel(
            sesionId: 's1',
            docenteId: 'd1',
            docente: 'Ana Pérez',
            aula: 'A-301 · Aula 301',
            asignatura: 'Cálculo',
            horaInicio: '08:00',
            horaFin: '10:00',
            minutosTranscurridos: 12,
          ),
        ],
        alertas: [AlertaActivaModel(docenteId: 'd2', docente: 'Luis Gómez')],
      );
    final cubit = TableroCubit(
      repository: repo,
      crearTemporizador: (espera, accion) => _TimerInerte(),
    )..iniciar();
    await _montar(tester, cubit, const TableroScreen());
    expect(find.text('7'), findsOneWidget);
    expect(find.text('Ana Pérez'), findsOneWidget);
    expect(find.text('A-301 · Aula 301'), findsOneWidget);
    expect(find.text('08:00 – 10:00'), findsOneWidget);
    expect(find.text('Luis Gómez'), findsOneWidget);

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();
    expect(repo.llamadas, ['tablero', 'tablero']);
  });

  testWidgets('ocupación: consulta por periodo y cambia la agrupación', (
    tester,
  ) async {
    final repo = FakeReportesOperativosRepository()
      ..ocupacionRespuesta = const ReporteOcupacionModel(
        filas: [
          FilaOcupacionModel(
            nombre: 'A-301 · Aula 301',
            sesiones: 4,
            porcentajeUtilizacion: 25,
          ),
        ],
        totales: FilaOcupacionModel(sesiones: 4, porcentajeUtilizacion: 25),
      );
    final cubit = OcupacionCubit(repository: repo, guardar: (_, __) {});
    await _montar(tester, cubit, const OcupacionScreen(puedeExportar: true));
    expect(find.text('Exportar XLSX'), findsOneWidget);

    await _elegir(tester, 'Sin periodo (usar fechas)', 'Periodo 2026-2');
    await tester.tap(find.text('Consultar'));
    await tester.pumpAndSettle();
    expect(find.text('A-301 · Aula 301'), findsOneWidget);
    expect(find.text('TOTALES'), findsOneWidget);

    await tester.tap(find.text('Por sede'));
    await tester.pumpAndSettle();
    expect(repo.llamadas, ['ocupacion:aula', 'ocupacion:sede']);
  });
}

class _TimerInerte implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}
