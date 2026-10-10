import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../domain/reportes_operativos_repository.dart';
import 'asistencia_grupo_state.dart';

/// Reporte de asistencia estudiantil por grupo (US-REP-05): periodo → grupo
/// visible para el usuario → porcentaje por estudiante y promedio.
class AsistenciaGrupoCubit extends Cubit<AsistenciaGrupoState> {
  final ReportesOperativosRepository _repository;

  AsistenciaGrupoCubit({required ReportesOperativosRepository repository})
    : _repository = repository,
      super(const AsistenciaGrupoState());

  Future<void> cargarPeriodos() async {
    try {
      final periodos = await _repository.periodos();
      if (!isClosed) emit(state.copyWith(periodos: periodos));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(error: () => mensajeDeError(e)));
    }
  }

  /// Elige el periodo y carga los grupos que el usuario puede consultar.
  Future<void> seleccionarPeriodo(String? periodoId) async {
    emit(
      state.copyWith(
        periodoId: () => periodoId,
        grupoId: () => null,
        reporte: () => null,
        grupos: const [],
        status: AsistenciaGrupoStatus.inicial,
        error: () => null,
      ),
    );
    if (periodoId == null || periodoId.isEmpty) return;
    try {
      final grupos = await _repository.grupos(periodoId);
      if (isClosed || state.periodoId != periodoId) return;
      emit(state.copyWith(grupos: grupos));
    } catch (e) {
      if (!isClosed) emit(state.copyWith(error: () => mensajeDeError(e)));
    }
  }

  /// Elige el grupo y consulta su reporte.
  Future<void> seleccionarGrupo(String? grupoId) async {
    emit(state.copyWith(grupoId: () => grupoId, reporte: () => null));
    if (grupoId == null || grupoId.isEmpty) return;
    await consultar();
  }

  Future<void> consultar() async {
    final grupoId = state.grupoId;
    if (grupoId == null) return;
    emit(
      state.copyWith(status: AsistenciaGrupoStatus.cargando, error: () => null),
    );
    try {
      final r = await _repository.asistenciaGrupo(grupoId);
      if (isClosed || state.grupoId != grupoId) return;
      emit(
        state.copyWith(status: AsistenciaGrupoStatus.cargado, reporte: () => r),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AsistenciaGrupoStatus.error,
          error: () => mensajeDeError(e),
        ),
      );
    }
  }
}
