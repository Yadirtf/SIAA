// marcaje_bloc.dart — BLoC para flujo de marcaje puntual (US-MAR-01..US-MAR-15)
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../privacidad/data/consentimiento_gate.dart';
import '../../../privacidad/data/consentimiento_requerido.dart';
import '../../data/repositories/marcaje_repository.dart';
import 'marcaje_event.dart';
import 'marcaje_state.dart';

class MarcajeBloc extends Bloc<MarcajeEvent, MarcajeState> {
  final MarcajeRepository _repository;
  final bool Function() _consentimientoOtorgado;

  MarcajeBloc({
    MarcajeRepository? repository,
    bool Function()? consentimientoOtorgado,
  })  : _repository = repository ?? MarcajeRepository(),
        _consentimientoOtorgado = consentimientoOtorgado ??
            (() => ConsentimientoGate.instance.permiteUbicacion),
        super(const MarcajeState()) {
    on<CargarSesionActivaEvent>(_onCargarSesionActiva);
    on<CapturarUbicacionEvent>(_onCapturarUbicacion);
    on<RealizarMarcajeEvent>(_onRealizarMarcaje);
    on<SincronizarOfflineEvent>(_onSincronizarOffline);
    on<RefrescarColaOfflineEvent>(_onRefrescarCola);
    on<ReintentarMarcajeOfflineEvent>(_onReintentarOffline);
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
        // El marcaje que cuenta es el de la ventana vigente (ENTRADA o SALIDA, US-MAR-15).
        if (sesion.marcajeVentanaRegistrado) {
          semaforo = SemaforoMarcaje.registrado;
        } else if (sesion.ventana.estaAbierta && sesion.admiteMarcaje) {
          semaforo = SemaforoMarcaje.buscandoGps;
        } else {
          semaforo = SemaforoMarcaje.fueraDeVentana;
        }
      }

      final consentido = _consentimientoOtorgado();
      emit(state.copyWith(
        isLoading: false,
        sesionActiva: sesion,
        clearSesion: sesion == null,
        colaOffline: cola,
        semaforo: semaforo,
        consentimientoRequerido: !consentido,
      ));

      // Si la ventana está abierta y aún admite marcaje, capturar GPS automáticamente
      // (solo con consentimiento vigente: US-LEG-01).
      if (consentido &&
          sesion != null &&
          sesion.ventana.estaAbierta &&
          sesion.admiteMarcaje) {
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
    if (!_consentimientoOtorgado()) {
      emit(state.copyWith(consentimientoRequerido: true));
      return;
    }
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
        error:
            'Precisión GPS actual (${location.precisionMetros.toStringAsFixed(1)}m) insuficiente. Se requiere menor a 30m.',
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
    if (!_consentimientoOtorgado()) {
      emit(state.copyWith(consentimientoRequerido: true));
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
        verificacion: event.verificacion,
        exigirAttestation: sesion.exigirAttestation,
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
        colaOffline: cola,
        semaforo: sem,
      ));

      // Salida aceptada sin permanencia en la respuesta: se recarga la sesión,
      // que trae el marcaje de salida con su permanencia (US-MAR-15 AC-02).
      if (event.tipo == 'SALIDA' &&
          resultado.esAceptado &&
          resultado.permanenciaMin == null) {
        add(const CargarSesionActivaEvent());
      }
    } on ConsentimientoRequeridoException catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        consentimientoRequerido: true,
        rechazosPorConsentimiento: state.rechazosPorConsentimiento + 1,
        error: e.mensaje,
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
    try {
      final resumen = await _repository.sincronizarMarcajesOffline();
      await _emitirCola(emit);
      if (resumen.evaluados > 0) {
        add(const CargarSesionActivaEvent());
      }
    } catch (e) {
      emit(
          state.copyWith(error: 'No fue posible sincronizar: ${e.toString()}'));
    }
  }

  Future<void> _onRefrescarCola(
    RefrescarColaOfflineEvent event,
    Emitter<MarcajeState> emit,
  ) =>
      _emitirCola(emit);

  Future<void> _onReintentarOffline(
    ReintentarMarcajeOfflineEvent event,
    Emitter<MarcajeState> emit,
  ) async {
    await _repository.reintentarMarcajeOffline(event.localId);
    await _emitirCola(emit);
    add(const SincronizarOfflineEvent());
  }

  Future<void> _emitirCola(Emitter<MarcajeState> emit) async {
    final cola = await _repository.obtenerColaOffline();
    emit(state.copyWith(colaOffline: cola));
  }
}
