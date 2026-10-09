import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/mensaje_error.dart';
import '../../data/models/sesion_model.dart';
import '../../domain/academico_repository.dart';
import 'sesiones_event.dart';
import 'sesiones_state.dart';

export 'sesiones_event.dart';
export 'sesiones_state.dart';

/// Sesiones de la semana consultada y sus cambios puntuales (US-ACA-05,
/// US-ACA-06, US-ACA-09). Tras cada cambio recarga con los mismos filtros.
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
        e,
        () =>
            _repository.cancelarSesion(sesionId: e.sesionId, motivo: e.motivo),
        'Sesión cancelada.',
      ),
    );
    on<ReasignarAulaSesionEvent>(
      (e, emit) => _accion(
        emit,
        e,
        () => _repository.reasignarAulaSesion(
          sesionId: e.sesionId,
          nuevoEspacioId: e.nuevoEspacioId,
          cambio: e.cambio,
        ),
        'Aula reasignada.',
      ),
    );
    on<AsignarDocenteReemplazoEvent>(
      (e, emit) => _accion(
        emit,
        e,
        () => _repository.asignarDocenteReemplazo(
          sesionId: e.sesionId,
          docenteId: e.docenteId,
          cambio: e.cambio,
        ),
        'Docente suplente asignado.',
      ),
    );
    on<ReprogramarSesionEvent>(
      (e, emit) => _accion(
        emit,
        e,
        () => _repository.reprogramarSesion(
          sesionId: e.sesionId,
          nueva: e.nueva,
          cambio: e.cambio,
        ),
        'Sesión reprogramada.',
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
      emit(SesionesError(mensajeDeError(e)));
    }
  }

  /// Ejecuta una acción sobre una sesión y recarga con los filtros vigentes.
  /// Si el diálogo espera el resultado, el error se le entrega a él; si no,
  /// la tabla sigue visible y el error se informa aparte.
  Future<void> _accion(
    Emitter<SesionesState> emit,
    AccionSesionEvent evento,
    Future<void> Function() accion,
    String exito,
  ) async {
    try {
      await accion();
    } catch (e) {
      final resultado = evento.resultado;
      if (resultado != null) return resultado.completeError(e);
      final previo = state;
      emit(
        previo is SesionesLoaded
            ? SesionesLoaded(previo.sesiones, errorMessage: mensajeDeError(e))
            : SesionesError(mensajeDeError(e)),
      );
      return;
    }
    evento.resultado?.complete();
    try {
      emit(SesionesLoaded(await _consultar(_ultima), successMessage: exito));
    } catch (e) {
      emit(SesionesError(mensajeDeError(e)));
    }
  }
}
