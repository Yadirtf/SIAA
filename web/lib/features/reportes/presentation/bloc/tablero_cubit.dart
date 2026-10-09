import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../domain/reportes_operativos_repository.dart';
import 'tablero_state.dart';

/// Fábrica de temporizadores; inyectable para probar la programación.
typedef CrearTemporizador = Timer Function(
  Duration espera,
  void Function() accion,
);

/// Tablero en vivo (US-REP-03). Se actualiza solo: cada intervalo sugerido
/// por el servidor más un desfase aleatorio de hasta la mitad de ese
/// intervalo, para que los tableros abiertos no consulten todos a la vez en
/// el pico del cambio de hora (AC-02).
class TableroCubit extends Cubit<TableroState> {
  final ReportesOperativosRepository _repository;
  final Random _random;
  final CrearTemporizador _crearTemporizador;
  Timer? _temporizador;

  TableroCubit({
    required ReportesOperativosRepository repository,
    Random? random,
    CrearTemporizador? crearTemporizador,
  }) : _repository = repository,
       _random = random ?? Random(),
       _crearTemporizador = crearTemporizador ?? Timer.new,
       super(const TableroState());

  /// Espera hasta la próxima consulta: [baseSegundos] más un desfase
  /// aleatorio en [0, baseSegundos / 2].
  static Duration esperaConDesfase(int baseSegundos, Random random) {
    final base = baseSegundos > 0 ? baseSegundos : 60;
    final desfaseMs = random.nextInt(base * 500 + 1);
    return Duration(seconds: base) + Duration(milliseconds: desfaseMs);
  }

  /// Primera carga y actualización periódica.
  Future<void> iniciar() async {
    await actualizar();
  }

  /// Consulta ahora y reprograma la siguiente actualización.
  Future<void> actualizar() async {
    _temporizador?.cancel();
    if (state.tablero == null) {
      emit(state.copyWith(status: TableroStatus.cargando, error: () => null));
    }
    try {
      final t = await _repository.tablero();
      if (isClosed) return;
      emit(
        state.copyWith(
          status: TableroStatus.cargado,
          tablero: t,
          error: () => null,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: state.tablero == null
              ? TableroStatus.error
              : TableroStatus.cargado,
          error: () => mensajeDeError(e),
        ),
      );
    }
    _programar();
  }

  void _programar() {
    if (isClosed) return;
    final base = state.tablero?.refrescoSugeridoSegundos ?? 60;
    final espera = esperaConDesfase(base, _random);
    emit(state.copyWith(proximaActualizacion: espera));
    _temporizador = _crearTemporizador(espera, actualizar);
  }

  @override
  Future<void> close() {
    _temporizador?.cancel();
    return super.close();
  }
}
