import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/academico/data/generacion_sesiones_remote_datasource.dart';
import 'package:siaa_web/features/academico/data/models/trabajo_model.dart';
import 'package:siaa_web/features/academico/presentation/cubit/generacion_sesiones_cubit.dart';

class _DsTrabajos extends GeneracionSesionesRemoteDataSource {
  final List<TrabajoModel> estados;
  Object? errorInicio;
  int consultas = 0;

  _DsTrabajos(this.estados);

  @override
  Future<TrabajoModel> iniciarGeneracion(
    String periodoId, {
    bool incluirPasadas = false,
  }) async {
    if (errorInicio != null) throw errorInicio!;
    return const TrabajoModel(id: 't9');
  }

  @override
  Future<TrabajoModel> consultarTrabajo(String trabajoId) async {
    expect(trabajoId, 't9');
    return estados[consultas++];
  }
}

void main() {
  test('consulta el trabajo hasta que termina y entrega el informe', () async {
    final ds = _DsTrabajos([
      const TrabajoModel(id: 't9', progreso: 10),
      const TrabajoModel(id: 't9', progreso: 60),
      const TrabajoModel(
        id: 't9',
        estado: TrabajoModel.completado,
        progreso: 100,
        resultado: {'sesionesGeneradas': 12, 'sesionesPasadasOmitidas': 3},
      ),
    ]);
    final cubit = GeneracionSesionesCubit(
      dataSource: ds,
      intervalo: Duration.zero,
    );
    addTearDown(cubit.close);
    final progresos = <int>[];
    final sub = cubit.stream.listen((s) {
      if (s.enCurso) progresos.add(s.progreso);
    });
    addTearDown(sub.cancel);

    await cubit.generar('p1');

    expect(ds.consultas, 3);
    expect(progresos, containsAllInOrder([10, 60]));
    expect(cubit.state.fase, FaseGeneracion.completada);
    expect(cubit.state.informe!.sesionesGeneradas, 12);
    expect(cubit.state.informe!.sesionesPasadasOmitidas, 3);
  });

  test('un trabajo FALLIDO termina con su error', () async {
    final cubit = GeneracionSesionesCubit(
      dataSource: _DsTrabajos([
        const TrabajoModel(
          id: 't9',
          estado: TrabajoModel.fallido,
          error: 'tiempo agotado',
        ),
      ]),
      intervalo: Duration.zero,
    );
    addTearDown(cubit.close);
    await cubit.generar('p1');
    expect(cubit.state.fase, FaseGeneracion.fallida);
    expect(cubit.state.error, 'tiempo agotado');
  });

  test('si el servidor rechaza el inicio informa el mensaje', () async {
    final ds = _DsTrabajos(const [])
      ..errorInicio = const ApiException(
        statusCode: 422,
        message: 'El periodo está cerrado',
      );
    final cubit = GeneracionSesionesCubit(dataSource: ds);
    addTearDown(cubit.close);
    await cubit.generar('p1');
    expect(cubit.state.fase, FaseGeneracion.fallida);
    expect(cubit.state.error, 'El periodo está cerrado');
  });
}
