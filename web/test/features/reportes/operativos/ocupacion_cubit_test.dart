import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/archivo_binario.dart';
import 'package:siaa_web/features/reportes/data/models/ocupacion_model.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/ocupacion_cubit.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/ocupacion_state.dart';

import 'fake_reportes_operativos_repository.dart';

void main() {
  late FakeReportesOperativosRepository repo;
  late List<(ArchivoBinario, String)> guardados;

  OcupacionCubit crear() => OcupacionCubit(
    repository: repo,
    guardar: (a, n) => guardados.add((a, n)),
    ahora: () => DateTime(2026, 10, 9, 8, 5),
  );

  setUp(() {
    repo = FakeReportesOperativosRepository();
    guardados = [];
  });

  test('sin periodo ni rango no consulta', () async {
    final cubit = crear();
    await cubit.consultar();
    expect(repo.llamadas, isEmpty);
    await cubit.close();
  });

  test('cambiar la agrupación vuelve a consultar con ella', () async {
    final cubit = crear()
      ..cambiarFiltro(const FiltroOcupacionModel(periodoId: 'p1'));
    await cubit.consultar();
    await cubit.agrupar('bloque');
    expect(repo.llamadas, ['ocupacion:aula', 'ocupacion:bloque']);
    expect(repo.ultimoFiltro!.toQuery(), {
      'agrupacion': 'bloque',
      'periodoId': 'p1',
    });
    expect(cubit.state.status, OcupacionStatus.cargado);
    await cubit.close();
  });

  test('exporta con nombre de respaldo', () async {
    final cubit = crear()
      ..cambiarFiltro(
        const FiltroOcupacionModel(desde: '2026-10-01', hasta: '2026-10-09'),
      );
    await cubit.exportar('xlsx');
    expect(repo.llamadas, ['exportar:xlsx']);
    expect(guardados.single.$2, 'ocupacion_20261009_0805.xlsx');
    expect(cubit.state.exportando, isNull);
    await cubit.close();
  });

  test('interpreta filas y totales', () {
    final r = ReporteOcupacionModel.fromJson({
      'filtro': {'agrupacion': 'sede'},
      'filas': [
        {'nombre': 'Sede Central', 'sesiones': 4, 'porcentajeUtilizacion': 25},
      ],
      'totales': {'nombre': 'TOTAL', 'horasProgramadas': 8.5},
    });
    expect(r.agrupacion, 'sede');
    expect(r.filas.single.porcentajeUtilizacion, 25);
    expect(r.totales.horasProgramadas, 8.5);
  });
}
