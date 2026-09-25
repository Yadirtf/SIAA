import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/parametros_repository.dart';
import 'parametros_event.dart';
import 'parametros_state.dart';

/// BLoC de parámetros en mobile — solo lectura para diagnóstico y calibración.
/// US-PAR-03: visualización de parámetros efectivos con su nivel de origen.
class ParametrosBloc extends Bloc<ParametrosEvent, ParametrosState> {
  final ParametrosRepository _repository;

  ParametrosBloc({required ParametrosRepository repository})
    : _repository = repository,
      super(const ParametrosInitial()) {
    on<CargarParametrosEfectivosEvent>(_onCargarEfectivos);
    on<CargarParametrosGlobalesEvent>(_onCargarGlobales);
  }

  Future<void> _onCargarEfectivos(
    CargarParametrosEfectivosEvent event,
    Emitter<ParametrosState> emit,
  ) async {
    emit(const ParametrosLoading());
    try {
      final snapshot = await _repository.obtenerEfectivos(
        sedeId: event.sedeId,
        facultadId: event.facultadId,
        bloqueId: event.bloqueId,
        espacioId: event.espacioId,
        asignacionId: event.asignacionId,
      );
      final label = _buildLabel(event);
      emit(ParametrosLoaded(snapshot: snapshot, ambitoLabel: label));
    } catch (e) {
      emit(ParametrosFailure(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCargarGlobales(
    CargarParametrosGlobalesEvent event,
    Emitter<ParametrosState> emit,
  ) async {
    emit(const ParametrosLoading());
    try {
      final snapshot = await _repository.obtenerGlobales();
      emit(
        ParametrosLoaded(
          snapshot: snapshot,
          ambitoLabel: 'Parámetros Globales del Sistema',
        ),
      );
    } catch (e) {
      emit(ParametrosFailure(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  String _buildLabel(CargarParametrosEfectivosEvent e) {
    if (e.asignacionId?.isNotEmpty == true) {
      return 'Parámetros de Asignación';
    }
    if (e.espacioId?.isNotEmpty == true) return 'Parámetros del Aula';
    if (e.bloqueId?.isNotEmpty == true) return 'Parámetros del Bloque';
    if (e.facultadId?.isNotEmpty == true) return 'Parámetros de Facultad';
    if (e.sedeId?.isNotEmpty == true) return 'Parámetros de Sede';
    return 'Parámetros Globales del Sistema';
  }
}
