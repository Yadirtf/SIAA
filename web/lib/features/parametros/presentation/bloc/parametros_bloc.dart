import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/parametros_repository.dart';
import 'parametros_event.dart';
import 'parametros_state.dart';

/// BLoC de parametrización para la consola web.
/// US-PAR-01: guarda parámetros por ámbito.
/// US-PAR-03: carga los efectivos con origen.
class ParametrosBloc extends Bloc<ParametrosEvent, ParametrosState> {
  final ParametrosRepository _repository;

  // Guarda el último evento de carga para poder refrescar tras guardar.
  CargarParametrosEfectivosEvent? _ultimoEventoCarga;

  ParametrosBloc({required ParametrosRepository repository})
    : _repository = repository,
      super(const ParametrosInitial()) {
    on<CargarParametrosEfectivosEvent>(_onCargarEfectivos);
    on<GuardarParametroEvent>(_onGuardarParametro);
    on<LimpiarMensajeParametroEvent>(_onLimpiarMensaje);
  }

  Future<void> _onCargarEfectivos(
    CargarParametrosEfectivosEvent event,
    Emitter<ParametrosState> emit,
  ) async {
    _ultimoEventoCarga = event;
    emit(const ParametrosLoading());
    try {
      final snapshot = await _repository.obtenerEfectivos(
        sedeId: event.sedeId,
        facultadId: event.facultadId,
        bloqueId: event.bloqueId,
        espacioId: event.espacioId,
        asignacionId: event.asignacionId,
      );
      emit(ParametrosLoaded(snapshot: snapshot));
    } catch (e) {
      emit(ParametrosFailure(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGuardarParametro(
    GuardarParametroEvent event,
    Emitter<ParametrosState> emit,
  ) async {
    final current = state;
    if (current is ParametrosLoaded) {
      emit(current.copyWith(isSaving: true, clearMessages: true));
    }
    try {
      await _repository.guardarParametro(event.request);

      // Refresca el snapshot para que la vista muestre el nuevo nivel de origen.
      if (_ultimoEventoCarga != null) {
        final refreshed = await _repository.obtenerEfectivos(
          sedeId: _ultimoEventoCarga!.sedeId,
          facultadId: _ultimoEventoCarga!.facultadId,
          bloqueId: _ultimoEventoCarga!.bloqueId,
          espacioId: _ultimoEventoCarga!.espacioId,
          asignacionId: _ultimoEventoCarga!.asignacionId,
        );
        emit(
          ParametrosLoaded(
            snapshot: refreshed,
            successMessage: 'Parámetro "${event.request.clave}" guardado.',
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      if (current is ParametrosLoaded) {
        emit(
          current.copyWith(isSaving: false, errorMessage: 'Error: $msg'),
        );
      } else {
        emit(ParametrosFailure(error: msg));
      }
    }
  }

  void _onLimpiarMensaje(
    LimpiarMensajeParametroEvent event,
    Emitter<ParametrosState> emit,
  ) {
    if (state is ParametrosLoaded) {
      emit((state as ParametrosLoaded).copyWith(clearMessages: true));
    }
  }
}
