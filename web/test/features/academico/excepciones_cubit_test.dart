import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/academico/data/excepciones_remote_datasource.dart';
import 'package:siaa_web/features/academico/data/generacion_sesiones_remote_datasource.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/academico/data/models/informe_generacion_model.dart';
import 'package:siaa_web/features/academico/presentation/cubit/excepciones_cubit.dart';

class _DsFalso extends ExcepcionesRemoteDataSource {
  String? ambitoId;

  @override
  Future<ExcepcionCreada> crear({
    required String nombre,
    required String tipo,
    required String ambito,
    String? ambitoId,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    this.ambitoId = ambitoId;
    return ExcepcionCreada(
      ExcepcionModel(
        id: 'e1',
        nombre: nombre,
        tipo: tipo,
        ambito: ambito,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      ),
      3,
    );
  }

  @override
  Future<FechasLiberadas> eliminar(String id) async => const FechasLiberadas(
    sesionesReactivables: 2,
    periodoIds: ['p1'],
    mensaje: 'Hay 2 sesiones que puede recuperar',
  );
}

class _GenFalsa extends GeneracionSesionesRemoteDataSource {
  final List<String> periodos = [];

  @override
  Future<InformeGeneracionModel> generar(String periodoId) async {
    periodos.add(periodoId);
    return const InformeGeneracionModel(
      asignacionesProcesadas: 1,
      sesionesGeneradas: 0,
      sesionesOmitidasIdempotencia: 0,
      sesionesReactivadas: 2,
      fechasExcluidas: [],
      asignacionesOmitidas: [],
      mensaje: '',
    );
  }
}

void main() {
  test('crear informa las sesiones canceladas y envía el ámbito', () async {
    final ds = _DsFalso();
    final cubit = ExcepcionesCubit(dataSource: ds, generacion: _GenFalsa());
    await cubit.crear(
      nombre: 'Paro',
      tipo: 'PARO',
      ambito: 'FACULTAD',
      ambitoId: 'fac-1',
      fechaInicio: '2026-10-10',
      fechaFin: '2026-10-10',
    );
    expect(ds.ambitoId, 'fac-1');
    expect(cubit.state.mensaje, contains('Se cancelaron 3 sesiones'));
  });

  test('eliminar ofrece regenerar y solo regenera a pedido', () async {
    final gen = _GenFalsa();
    final cubit = ExcepcionesCubit(dataSource: _DsFalso(), generacion: gen);
    await cubit.eliminar('e1');
    expect(cubit.state.liberadas?.sesionesReactivables, 2);
    expect(gen.periodos, isEmpty);
    await cubit.regenerar(cubit.state.liberadas!);
    expect(gen.periodos, ['p1']);
    expect(cubit.state.mensaje, 'Se recuperaron 2 sesiones.');
  });
}
