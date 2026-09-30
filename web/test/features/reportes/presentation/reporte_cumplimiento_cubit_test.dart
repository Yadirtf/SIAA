import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/archivo_binario.dart';
import 'package:siaa_web/features/reportes/data/models/filtro_reporte_model.dart';
import 'package:siaa_web/features/reportes/data/models/reporte_cumplimiento_model.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/reporte_cumplimiento_cubit.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/reporte_cumplimiento_state.dart';

import 'fake_reportes_repository.dart';

void main() {
  late FakeReportesRepository repo;
  late List<(ArchivoBinario, String)> guardados;

  ReporteCumplimientoCubit crear() => ReporteCumplimientoCubit(
    repository: repo,
    guardar: (a, n) => guardados.add((a, n)),
    ahora: () => DateTime(2026, 9, 29, 10, 30),
  );

  setUp(() {
    repo = FakeReportesRepository()
      ..reporte = const ReporteCumplimientoModel(falsosRechazos: 2);
    guardados = [];
  });

  test('sin periodo ni rango no consulta y avisa', () async {
    final cubit = crear();
    final estados = <ReporteCumplimientoState>[];
    final sub = cubit.stream.listen(estados.add);
    await cubit.consultar();
    expect(repo.llamadas, isEmpty);
    expect(
      estados.last.mensajeError,
      ReporteCumplimientoCubit.mensajeFiltroIncompleto,
    );
    await sub.cancel();
    await cubit.close();
  });

  test('consulta con periodo y guarda el reporte', () async {
    final cubit = crear()
      ..cambiarFiltro(const FiltroReporteModel(periodoId: 'p1'));
    await cubit.consultar();
    expect(repo.ultimoFiltro!.periodoId, 'p1');
    expect(cubit.state.status, ReporteStatus.cargado);
    expect(cubit.state.reporte!.falsosRechazos, 2);
    await cubit.close();
  });

  test('un 422 deja el estado en error con el mensaje', () async {
    repo.error = const ApiException(
      message: 'Indique periodoId o desde y hasta',
      statusCode: 422,
    );
    final cubit = crear()
      ..cambiarFiltro(const FiltroReporteModel(periodoId: 'p1'));
    await cubit.consultar();
    expect(cubit.state.status, ReporteStatus.error);
    expect(cubit.state.error, 'Indique periodoId o desde y hasta');
    await cubit.close();
  });

  test('exportar descarga con nombre de respaldo o el del servidor', () async {
    final cubit = crear()
      ..cambiarFiltro(
        const FiltroReporteModel(desde: '2026-09-01', hasta: '2026-09-30'),
      );
    await cubit.exportar('xlsx');
    expect(repo.llamadas, ['exportar:xlsx']);
    expect(guardados.single.$2, 'cumplimiento_20260929_1030.xlsx');
    expect(cubit.state.exportando, isNull);

    repo.nombreServidor = 'cumplimiento.pdf';
    await cubit.exportar('pdf');
    expect(guardados.last.$1.nombre, 'cumplimiento.pdf');
    await cubit.close();
  });
}
