// reportes_test.dart — Reporte de cumplimiento en móvil (RF-REP-001)
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/reportes/data/reportes_remote_datasource.dart';
import 'package:siaa_mobile/features/reportes/domain/reporte_cumplimiento.dart';
import 'package:siaa_mobile/features/reportes/presentation/cubit/reportes_cubit.dart';
import 'package:siaa_mobile/features/reportes/presentation/screens/reportes_screen.dart';

const _json = {
  'generadoEn': '2026-09-30T12:00:00Z',
  'falsosRechazos': 1,
  'docentes': [
    {
      'docenteId': 'd-1',
      'nombre': 'Ana Gómez',
      'sesiones': 10,
      'porcentajeCumplimiento': 95.0,
      'tardanzas': 1,
      'ausenciasInjustificadas': 0
    },
    {
      'docenteId': 'd-2',
      'nombre': 'Luis Pérez',
      'sesiones': 8,
      'porcentajeCumplimiento': 62.5,
      'tardanzas': 2,
      'ausenciasInjustificadas': 3
    },
  ],
  'totales': {
    'sesiones': 18,
    'horasProgramadas': 36,
    'horasDictadas': 30,
    'porcentajeCumplimiento': 83.3,
    'tardanzas': 3,
    'ausenciasInjustificadas': 3
  },
};

class _RemoteFake extends ReportesRemoteDataSource {
  final List<Map<String, Object?>> consultas = [];
  _RemoteFake() : super(dio: Dio());

  @override
  Future<ReporteCumplimiento> cumplimiento(
      {String? periodoId, DateTime? desde, DateTime? hasta}) async {
    consultas.add({'periodoId': periodoId, 'desde': desde, 'hasta': hasta});
    return ReporteCumplimiento.fromJson(_json);
  }

  @override
  Future<List<PeriodoOpcion>> periodos() async =>
      [const PeriodoOpcion(id: 'p-1', nombre: '2026-2')];
}

void main() {
  test('parsea filas y ordena de menor a mayor cumplimiento', () {
    final r = ReporteCumplimiento.fromJson(_json);
    expect(r.docentes.map((d) => d.nombreVisible), ['Luis Pérez', 'Ana Gómez']);
    expect(r.totales.sesiones, 18);
    expect(r.falsosRechazos, 1);
  });

  test('consulta el mes en curso y luego por periodo', () async {
    final remote = _RemoteFake();
    final cubit = ReportesCubit(remote: remote, hoy: DateTime(2026, 9, 30));
    await cubit.iniciar();
    expect(remote.consultas.first['desde'], DateTime(2026, 9, 1));
    expect(remote.consultas.first['hasta'], DateTime(2026, 9, 30));
    expect(cubit.state.estado, EstadoReporte.listo);
    await cubit.elegirPeriodo(cubit.state.periodos.single);
    expect(remote.consultas.last['periodoId'], 'p-1');
    await cubit.close();
  });

  testWidgets(
      'la pantalla muestra totales, docentes por nombre y nota de exportación',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ReportesScreen(remote: _RemoteFake()))));
    await tester.pumpAndSettle();
    expect(find.text('83.3 %'), findsOneWidget);
    expect(find.text('Luis Pérez'), findsOneWidget);
    expect(find.text('62.5 %'), findsOneWidget);
    expect(find.textContaining('consola web'), findsOneWidget);
  });
}
