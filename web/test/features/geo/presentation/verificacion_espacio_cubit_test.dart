import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/geo/data/models/geo_models.dart';
import 'package:siaa_web/features/geo/presentation/bloc/geo_bloc.dart';
import 'package:siaa_web/features/geo/presentation/bloc/geo_event.dart';
import 'package:siaa_web/features/geo/presentation/bloc/geo_state.dart';
import 'package:siaa_web/features/geo/presentation/bloc/verificacion_espacio_cubit.dart';
import 'package:siaa_web/features/geo/presentation/bloc/verificacion_espacio_state.dart';

import 'fake_geo_repository.dart';

void main() {
  late FakeGeoRepository repo;
  late VerificacionEspacioCubit cubit;

  setUp(() {
    repo = FakeGeoRepository()..espacios = [espacioDePrueba()];
    cubit = VerificacionEspacioCubit(repository: repo, espacioId: 'e1');
  });

  tearDown(() => cubit.close());

  test('guardar pasa por guardando y termina con el espacio', () async {
    const v = VerificacionEspacioModel(qrCodigo: 'SIAA-AUL-101-ABC123');
    final estados = <EstadoVerificacion>[];
    final sub = cubit.stream.listen((s) => estados.add(s.estado));

    await cubit.guardar(v);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(estados, [
      EstadoVerificacion.guardando,
      EstadoVerificacion.guardado,
    ]);
    expect(repo.ultimoEspacioId, 'e1');
    expect(cubit.state.espacio!.verificacionComplementaria, v);
  });

  test('un 422 deja los errores por campo y vuelve a edición', () async {
    repo.errorVerificacion = const ApiException(
      message: 'Verificación complementaria inválida',
      statusCode: 422,
      details: {
        'detalles': [
          {'campo': 'wifiBssids', 'error': 'BSSID inválido: zz'},
        ],
      },
    );

    await cubit.guardar(const VerificacionEspacioModel(wifiBssids: ['zz']));

    expect(cubit.state.estado, EstadoVerificacion.editando);
    expect(cubit.state.errorDe('wifiBssids'), 'BSSID inválido: zz');
    expect(cubit.state.errorDe('qrCodigo'), isNull);
    expect(cubit.state.mensajeError, 'Verificación complementaria inválida');
  });

  test('quitar envía todo vacío', () async {
    await cubit.quitar();
    expect(repo.ultimaVerificacion, VerificacionEspacioModel.vacia);
    expect(cubit.state.espacio!.tieneVerificacion, isFalse);
  });

  test('GeoBloc reemplaza el espacio actualizado sin recargar', () async {
    final bloc = GeoBloc(repository: repo);
    bloc.add(const LoadGeoDataEvent());
    await bloc.stream.firstWhere((s) => s is GeoLoaded);

    final actualizado = espacioDePrueba(
      verificacion: const VerificacionEspacioModel(bleUuid: 'uuid'),
    );
    bloc.add(EspacioActualizadoEvent(actualizado));
    final s = await bloc.stream.first as GeoLoaded;

    expect(s.espacios.single.tieneVerificacion, isTrue);
    await bloc.close();
  });
}
