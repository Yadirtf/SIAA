import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/dispositivos_repository.dart';
import 'dispositivos_event.dart';
import 'dispositivos_state.dart';

class DispositivosBloc extends Bloc<DispositivosEvent, DispositivosState> {
  final DispositivosRepository _repository;

  DispositivosBloc({required DispositivosRepository repository})
    : _repository = repository,
      super(const DispositivosInitial()) {
    on<CargarDispositivosEvent>(_onCargarDispositivos);
    on<AprobarDispositivoEvent>(_onAprobarDispositivo);
    on<RevocarDispositivoEvent>(_onRevocarDispositivo);
    on<LimpiarMensajeDispositivoEvent>(_onLimpiarMensaje);
  }

  Future<void> _onCargarDispositivos(
    CargarDispositivosEvent event,
    Emitter<DispositivosState> emit,
  ) async {
    emit(const DispositivosLoading());
    try {
      final dispositivos = await _repository.obtenerDispositivosUsuario(
        event.usuarioId,
      );
      emit(
        DispositivosLoaded(
          dispositivos: dispositivos,
          usuarioId: event.usuarioId,
        ),
      );
    } catch (e) {
      emit(
        DispositivosFailure(
          error: e.toString().replaceAll('Exception: ', ''),
          usuarioId: event.usuarioId,
        ),
      );
    }
  }

  Future<void> _onAprobarDispositivo(
    AprobarDispositivoEvent event,
    Emitter<DispositivosState> emit,
  ) async {
    final currentState = state;
    if (currentState is DispositivosLoaded) {
      emit(currentState.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _repository.aprobarDispositivo(event.dispositivoId);
      final refreshed = await _repository.obtenerDispositivosUsuario(
        event.usuarioId,
      );
      emit(
        DispositivosLoaded(
          dispositivos: refreshed,
          usuarioId: event.usuarioId,
          actionSuccessMessage: 'Dispositivo aprobado exitosamente.',
        ),
      );
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (currentState is DispositivosLoaded) {
        emit(
          currentState.copyWith(
            isProcessing: false,
            actionErrorMessage: 'Error al aprobar dispositivo: $errorMsg',
          ),
        );
      } else {
        emit(DispositivosFailure(error: errorMsg, usuarioId: event.usuarioId));
      }
    }
  }

  Future<void> _onRevocarDispositivo(
    RevocarDispositivoEvent event,
    Emitter<DispositivosState> emit,
  ) async {
    final currentState = state;
    if (currentState is DispositivosLoaded) {
      emit(currentState.copyWith(isProcessing: true, clearMessages: true));
    }

    try {
      await _repository.revocarDispositivo(
        event.dispositivoId,
        motivo: event.motivo,
      );
      final refreshed = await _repository.obtenerDispositivosUsuario(
        event.usuarioId,
      );
      emit(
        DispositivosLoaded(
          dispositivos: refreshed,
          usuarioId: event.usuarioId,
          actionSuccessMessage: 'Acceso del dispositivo revocado exitosamente.',
        ),
      );
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (currentState is DispositivosLoaded) {
        emit(
          currentState.copyWith(
            isProcessing: false,
            actionErrorMessage: 'Error al revocar dispositivo: $errorMsg',
          ),
        );
      } else {
        emit(DispositivosFailure(error: errorMsg, usuarioId: event.usuarioId));
      }
    }
  }

  void _onLimpiarMensaje(
    LimpiarMensajeDispositivoEvent event,
    Emitter<DispositivosState> emit,
  ) {
    if (state is DispositivosLoaded) {
      emit((state as DispositivosLoaded).copyWith(clearMessages: true));
    }
  }
}
