// marcaje_state.dart — Estado reactivo y semáforo de 6 estados (SRS §9.1)
import 'package:equatable/equatable.dart';
import '../../data/services/location_service.dart';
import '../../domain/models/marcaje_result_model.dart';
import '../../domain/models/sesion_activa_model.dart';

enum SemaforoMarcaje {
  fueraDeVentana,
  buscandoGps,
  precisionInsuficiente,
  listo,
  fueraDeAula,
  registrado,
}

class MarcajeState extends Equatable {
  final bool isLoading;
  final bool isCapturingGps;
  final bool isSubmitting;
  final SesionActivaModel? sesionActiva;
  final LocationResult? location;
  final MarcajeResultModel? ultimoResultado;
  final int colaOfflineCount;
  final String? error;
  final SemaforoMarcaje semaforo;

  const MarcajeState({
    this.isLoading = false,
    this.isCapturingGps = false,
    this.isSubmitting = false,
    this.sesionActiva,
    this.location,
    this.ultimoResultado,
    this.colaOfflineCount = 0,
    this.error,
    this.semaforo = SemaforoMarcaje.fueraDeVentana,
  });

  bool get puedeMarcar =>
      !isSubmitting &&
      sesionActiva != null &&
      sesionActiva!.ventana.estaAbierta &&
      semaforo == SemaforoMarcaje.listo;

  MarcajeState copyWith({
    bool? isLoading,
    bool? isCapturingGps,
    bool? isSubmitting,
    SesionActivaModel? sesionActiva,
    bool clearSesion = false,
    LocationResult? location,
    MarcajeResultModel? ultimoResultado,
    bool clearResultado = false,
    int? colaOfflineCount,
    String? error,
    bool clearError = false,
    SemaforoMarcaje? semaforo,
  }) {
    return MarcajeState(
      isLoading: isLoading ?? this.isLoading,
      isCapturingGps: isCapturingGps ?? this.isCapturingGps,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      sesionActiva: clearSesion ? null : (sesionActiva ?? this.sesionActiva),
      location: location ?? this.location,
      ultimoResultado: clearResultado ? null : (ultimoResultado ?? this.ultimoResultado),
      colaOfflineCount: colaOfflineCount ?? this.colaOfflineCount,
      error: clearError ? null : (error ?? this.error),
      semaforo: semaforo ?? this.semaforo,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isCapturingGps,
        isSubmitting,
        sesionActiva,
        location,
        ultimoResultado,
        colaOfflineCount,
        error,
        semaforo,
      ];
}
