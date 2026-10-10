// mi_asistencia_cubit.dart — Carga "Mi asistencia" del estudiante (US-MAR-13 AC-05)
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_error.dart';
import '../../data/asistencia_remote_datasource.dart';
import '../../domain/asistencia_asignatura.dart';

class MiAsistenciaState extends Equatable {
  final bool cargando;
  final List<AsistenciaAsignatura> asignaturas;
  final String? error;

  const MiAsistenciaState({
    this.cargando = true,
    this.asignaturas = const [],
    this.error,
  });

  @override
  List<Object?> get props => [cargando, asignaturas, error];
}

class MiAsistenciaCubit extends Cubit<MiAsistenciaState> {
  final AsistenciaRemoteDataSource _remote;

  MiAsistenciaCubit({AsistenciaRemoteDataSource? remote})
      : _remote = remote ?? AsistenciaRemoteDataSource(),
        super(const MiAsistenciaState());

  Future<void> cargar() async {
    emit(MiAsistenciaState(asignaturas: state.asignaturas));
    try {
      final lista = await _remote.miAsistencia();
      if (isClosed) return;
      emit(MiAsistenciaState(cargando: false, asignaturas: lista));
    } catch (e) {
      if (isClosed) return;
      emit(MiAsistenciaState(
        cargando: false,
        asignaturas: state.asignaturas,
        error: mensajeDeError(e),
      ));
    }
  }
}
