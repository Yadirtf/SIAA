// marcaje_bloc.dart — BLoC para flujo de marcaje puntual (US-MAR-01..US-MAR-15)
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/marcaje_repository.dart';
import '../../data/services/location_service.dart';
import 'marcaje_event.dart';
import 'marcaje_state.dart';

class MarcajeBloc extends Bloc<MarcajeEvent, MarcajeState> {
  final MarcajeRepository _repository;

  MarcajeBloc({MarcajeRepository? repository})
      : _repository = repository ?? MarcajeRepository(),
        super(const MarcajeState()) {
    on<CargarSesionActivaEvent>(_onCargarSesionActiva);
    on<CapturarUbicacionEvent>(_onCapturarUbicacion);
    on<RealizarMarcajeEvent>(_onRealizarMarcaje);
    on<SincronizarOfflineEvent>(_onSincronizarOffline);
  }

  Future<void> _onCargarSesionActiva(
    CargarSesionActivaEvent event,
    Emitter<MarcajeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final sesion = await _repository.obtenerSesionActiva();
      final cola = await _repository.obtenerColaOffline();

      SemaforoMarcaje semaforo = SemaforoMarcaje.fueraDeVentana;
      if (sesion != null) {
        if (sesion.tieneMarcajeEntrada) {
          semaforo = SemaforoMarcaje.registrado;
        } else if (sesion.ventana.estaAbierta) {
          semaforo = SemaforoMarcaje.buscandoGps;
        } else {
          semaforo = SemaforoMarcaje.fueraDeVentana;
        }
      }

      emit(state.copyWith(
        isLoading: false,
        sesionActiva: sesion,
        clearSesion: sesion == null,
        colaOfflineCount: cola.length,
        semaforo: semaforo,
      ));

      // Si la ventana está abierta y no tiene entrada, capturar GPS automáticamente
      if (sesion != null && sesion.ventana.estaAbierta && !sesion.tieneMarcajeEntrada) {
        add(const CapturarUbicacionEvent());
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'No fue posible sincronizar la sesión actual: ${e.toString()}',
      ));
    }
  }

  Future<void> _onCapturarUbicacion(
    CapturarUbicacionEvent event,
    Emitter<MarcajeState> emit,
  ) async {
    emit(state.copyWith(
      isCapturingGps: true,
      semaforo: SemaforoMarcaje.buscandoGps,
      clearError: true,
    ));

    final location = await _repository.capturarUbicacion();
    if (location.hasError) {
      emit(state.copyWith(
        isCapturingGps: false,
        location: location,
        semaforo: SemaforoMarcaje.precisionInsuficiente,
        error: location.error,
      ));
      return;
    }

    // Regla de umbral de precisión móvil: > 30m se considera insuficiente
    if (location.precisionMetros > 30.0) {
      emit(state.copyWith(
        isCapturingGps: false,
        location: location,
        semaforo: SemaforoMarcaje.precisionInsuficiente,
        error: 'Precisión GPS actual (${location.precisionMetros.toStringAsFixed(1)}m) insuficiente. Se requiere menor a 30m.',
      ));
      return;
    }

    emit(state.copyWith(
      isCapturingGps: false,
      location: location,
      semaforo: SemaforoMarcaje.listo,
      clearError: true,
    ));
  }

  Future<void> _onRealizarMarcaje(
    RealizarMarcajeEvent event,
    Emitter<MarcajeState> emit,
  ) async {
    if (state.isSubmitting) return; // Idempotencia en cliente (US-MAR-05 AC-04)

    final sesion = state.sesionActiva;
    if (sesion == null) {
      emit(state.copyWith(error: 'No hay sesión activa para marcar'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    // Si aún no tenemos lectura de ubicación fresca, obtenerla primero
    var loc = state.location;
    if (loc == null || loc.hasError) {
      loc = await _repository.capturarUbicacion();
      if (loc.hasError) {
        emit(state.copyWith(
          isSubmitting: false,
          location: loc,
          error: loc.error,
          semaforo: SemaforoMarcaje.precisionInsuficiente,
        ));
        return;
      }
    }

    try {
      final resultado = await _repository.realizarMarcaje(
        sesionId: sesion.id,
        tipo: event.tipo,
        location: loc,
      );

      final cola = await _repository.obtenerColaOffline();

      SemaforoMarcaje sem = state.semaforo;
      if (resultado.esAceptado) {
        sem = SemaforoMarcaje.registrado;
      } else if (resultado.motivoRechazo == 'FUERA_DE_POLIGONO') {
        sem = SemaforoMarcaje.fueraDeAula;
      } else if (resultado.esPrecisionInsuficiente) {
        sem = SemaforoMarcaje.precisionInsuficiente;
      }

      emit(state.copyWith(
        isSubmitting: false,
        ultimoResultado: resultado,
        colaOfflineCount: cola.length,
        semaforo: sem,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        error: 'Error de comunicación: ${e.toString()}',
      ));
    }
  }

  Future<void> _onSincronizarOffline(
    SincronizarOfflineEvent event,
    Emitter<MarcajeState> emit,
  ) async {
    final sincs = await _repository.sincronizarMarcajesOffline();
    final cola = await _repository.obtenerColaOffline();
    emit(state.copyWith(colaOfflineCount: cola.length));
    if (sincs > 0) {
      add(const CargarSesionActivaEvent());
    }
  }
}
