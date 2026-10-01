import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
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

  /// Rango de fechas AAAA-MM-DD, inclusivo (la tabla consulta una semana).
  final String? desde;
  final String? hasta;

  const LoadSesionesEvent({
    this.periodoId,
    this.docenteId,
    this.espacioId,
    this.fecha,
    this.estado,
    this.desde,
    this.hasta,
  });

  @override
  List<Object?> get props => [
    periodoId,
    docenteId,
    espacioId,
    fecha,
    estado,
    desde,
    hasta,
  ];
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

  /// Error de una acción (cancelar, reasignar); la tabla se conserva.
  final String? errorMessage;

  const SesionesLoaded(this.sesiones, {this.successMessage, this.errorMessage});

  @override
  List<Object?> get props => [sesiones, successMessage, errorMessage];
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

  /// Última consulta, para recargar con los mismos filtros tras una acción.
  LoadSesionesEvent _ultima = const LoadSesionesEvent();

  SesionesBloc({required AcademicoRepository repository})
    : _repository = repository,
      super(const SesionesInitial()) {
    on<LoadSesionesEvent>(_onLoadSesiones);
    on<CancelarSesionEvent>(
      (e, emit) => _accion(
        emit,
        () =>
            _repository.cancelarSesion(sesionId: e.sesionId, motivo: e.motivo),
        'Sesión cancelada.',
      ),
    );
    on<ReasignarAulaSesionEvent>(
      (e, emit) => _accion(
        emit,
        () => _repository.reasignarAulaSesion(
          sesionId: e.sesionId,
          nuevoEspacioId: e.nuevoEspacioId,
          motivo: e.motivo,
        ),
        'Aula reasignada.',
      ),
    );
    on<AsignarDocenteReemplazoEvent>(
      (e, emit) => _accion(
        emit,
        () => _repository.asignarDocenteReemplazo(
          sesionId: e.sesionId,
          docenteId: e.docenteId,
          motivo: e.motivo,
        ),
        'Docente suplente asignado.',
      ),
    );
  }

  Future<List<SesionModel>> _consultar(LoadSesionesEvent e) =>
      _repository.getSesiones(
        periodoId: e.periodoId,
        docenteId: e.docenteId,
        espacioId: e.espacioId,
        fecha: e.fecha,
        estado: e.estado,
        desde: e.desde,
        hasta: e.hasta,
      );

  Future<void> _onLoadSesiones(
    LoadSesionesEvent event,
    Emitter<SesionesState> emit,
  ) async {
    _ultima = event;
    emit(const SesionesLoading());
    try {
      emit(SesionesLoaded(await _consultar(event)));
    } catch (e) {
      emit(SesionesError(_cleanError(e)));
    }
  }

  /// Ejecuta una acción sobre una sesión y recarga con los filtros vigentes.
  /// Si falla, la tabla sigue visible y el error se informa aparte.
  Future<void> _accion(
    Emitter<SesionesState> emit,
    Future<void> Function() accion,
    String exito,
  ) async {
    try {
      await accion();
      emit(SesionesLoaded(await _consultar(_ultima), successMessage: exito));
    } catch (e) {
      final previo = state;
      emit(
        previo is SesionesLoaded
            ? SesionesLoaded(previo.sesiones, errorMessage: _cleanError(e))
            : SesionesError(_cleanError(e)),
      );
    }
  }

  String _cleanError(dynamic e) {
    if (e is ApiException) return e.message;
    return e
        .toString()
        .replaceAll('ApiException: ', '')
        .replaceAll('Exception: ', '');
  }
}
