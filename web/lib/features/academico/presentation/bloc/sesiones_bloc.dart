import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/sesion_model.dart';
import '../../domain/academico_repository.dart';

// ─── Events ───
abstract class SesionesEvent extends Equatable {
  const SesionesEvent();
  @override
  List<Object?> get props => [];
}

class LoadSesionesEvent extends SesionesEvent {
  final String? periodoId;
  final String? docenteId;
  final String? espacioId;
  final String? fecha;
  final String? estado;

  const LoadSesionesEvent({
    this.periodoId,
    this.docenteId,
    this.espacioId,
    this.fecha,
    this.estado,
  });

  @override
  List<Object?> get props => [periodoId, docenteId, espacioId, fecha, estado];
}

class CancelarSesionEvent extends SesionesEvent {
  final String sesionId;
  final String motivo;

  const CancelarSesionEvent({required this.sesionId, required this.motivo});

  @override
  List<Object?> get props => [sesionId, motivo];
}

class ReasignarAulaSesionEvent extends SesionesEvent {
  final String sesionId;
  final String nuevoEspacioId;
  final String? motivo;

  const ReasignarAulaSesionEvent({
    required this.sesionId,
    required this.nuevoEspacioId,
    this.motivo,
  });

  @override
  List<Object?> get props => [sesionId, nuevoEspacioId, motivo];
}

class AsignarDocenteReemplazoEvent extends SesionesEvent {
  final String sesionId;
  final String docenteId;
  final String? motivo;

  const AsignarDocenteReemplazoEvent({
    required this.sesionId,
    required this.docenteId,
    this.motivo,
  });

  @override
  List<Object?> get props => [sesionId, docenteId, motivo];
}

// ─── States ───
abstract class SesionesState extends Equatable {
  const SesionesState();
  @override
  List<Object?> get props => [];
}

class SesionesInitial extends SesionesState {
  const SesionesInitial();
}

class SesionesLoading extends SesionesState {
  const SesionesLoading();
}

class SesionesLoaded extends SesionesState {
  final List<SesionModel> sesiones;
  final String? successMessage;

  const SesionesLoaded(this.sesiones, {this.successMessage});

  @override
  List<Object?> get props => [sesiones, successMessage];
}

class SesionesError extends SesionesState {
  final String message;
  const SesionesError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── BLoC ───
class SesionesBloc extends Bloc<SesionesEvent, SesionesState> {
  final AcademicoRepository _repository;

  SesionesBloc({required AcademicoRepository repository})
      : _repository = repository,
        super(const SesionesInitial()) {
    on<LoadSesionesEvent>(_onLoadSesiones);
    on<CancelarSesionEvent>(_onCancelarSesion);
    on<ReasignarAulaSesionEvent>(_onReasignarAulaSesion);
    on<AsignarDocenteReemplazoEvent>(_onAsignarDocenteReemplazo);
  }

  Future<void> _onLoadSesiones(
    LoadSesionesEvent event,
    Emitter<SesionesState> emit,
  ) async {
    emit(const SesionesLoading());
    try {
      final list = await _repository.getSesiones(
        periodoId: event.periodoId,
        docenteId: event.docenteId,
        espacioId: event.espacioId,
        fecha: event.fecha,
        estado: event.estado,
      );
      emit(SesionesLoaded(list));
    } catch (e) {
      emit(SesionesError(_cleanError(e)));
    }
  }

  Future<void> _onCancelarSesion(
    CancelarSesionEvent event,
    Emitter<SesionesState> emit,
  ) async {
    try {
      await _repository.cancelarSesion(
        sesionId: event.sesionId,
        motivo: event.motivo,
      );
      add(const LoadSesionesEvent());
    } catch (e) {
      emit(SesionesError(_cleanError(e)));
    }
  }

  Future<void> _onReasignarAulaSesion(
    ReasignarAulaSesionEvent event,
    Emitter<SesionesState> emit,
  ) async {
    try {
      await _repository.reasignarAulaSesion(
        sesionId: event.sesionId,
        nuevoEspacioId: event.nuevoEspacioId,
        motivo: event.motivo,
      );
      add(const LoadSesionesEvent());
    } catch (e) {
      emit(SesionesError(_cleanError(e)));
    }
  }

  Future<void> _onAsignarDocenteReemplazo(
    AsignarDocenteReemplazoEvent event,
    Emitter<SesionesState> emit,
  ) async {
    try {
      await _repository.asignarDocenteReemplazo(
        sesionId: event.sesionId,
        docenteId: event.docenteId,
        motivo: event.motivo,
      );
      add(const LoadSesionesEvent());
    } catch (e) {
      emit(SesionesError(_cleanError(e)));
    }
  }

  String _cleanError(dynamic e) {
    return e
        .toString()
        .replaceAll('ApiException: ', '')
        .replaceAll('Exception: ', '');
  }
}
