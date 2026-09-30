// marcaje_state.dart — Estado reactivo y semáforo de 6 estados (SRS §9.1)
import 'package:equatable/equatable.dart';
import '../../data/services/location_service.dart';
import '../../domain/models/marcaje_result_model.dart';
import '../../domain/models/offline_marcaje_item.dart';
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

  /// Snapshot de la cola offline local (US-MAR-11).
  final List<OfflineMarcajeItem> colaOffline;
  final String? error;
  final SemaforoMarcaje semaforo;

  /// Sin aceptación del aviso de privacidad: marcaje deshabilitado (US-LEG-01 AC-05).
  final bool consentimientoRequerido;

  /// Se incrementa cuando el servidor respondió 403 CONSENTIMIENTO_REQUERIDO
  /// para que la pantalla presente el aviso.
  final int rechazosPorConsentimiento;

  const MarcajeState({
    this.isLoading = false,
    this.isCapturingGps = false,
    this.isSubmitting = false,
    this.sesionActiva,
    this.location,
    this.ultimoResultado,
    this.colaOffline = const [],
    this.error,
    this.semaforo = SemaforoMarcaje.fueraDeVentana,
    this.consentimientoRequerido = false,
    this.rechazosPorConsentimiento = 0,
  });

  bool get puedeMarcar =>
      !isSubmitting &&
      !consentimientoRequerido &&
      sesionActiva != null &&
      sesionActiva!.ventana.estaAbierta &&
      semaforo == SemaforoMarcaje.listo;

  List<OfflineMarcajeItem> _enEstado(EstadoSincronizacion e) =>
      colaOffline.where((it) => it.estado == e).toList();

  /// Marcajes aún por enviar (incluye los que esperan su próximo reintento).
  int get colaOfflineCount => _enEstado(EstadoSincronizacion.pendiente).length;

  /// Evaluados por el servidor y no aceptados: el docente puede justificar.
  List<OfflineMarcajeItem> get colaRechazados =>
      _enEstado(EstadoSincronizacion.rechazado);

  /// Agotaron los reintentos automáticos: admiten reintento manual.
  List<OfflineMarcajeItem> get colaFallidos =>
      _enEstado(EstadoSincronizacion.fallido);

  MarcajeState copyWith({
    bool? isLoading,
    bool? isCapturingGps,
    bool? isSubmitting,
    SesionActivaModel? sesionActiva,
    bool clearSesion = false,
    LocationResult? location,
    MarcajeResultModel? ultimoResultado,
    bool clearResultado = false,
    List<OfflineMarcajeItem>? colaOffline,
    String? error,
    bool clearError = false,
    SemaforoMarcaje? semaforo,
    bool? consentimientoRequerido,
    int? rechazosPorConsentimiento,
  }) {
    return MarcajeState(
      isLoading: isLoading ?? this.isLoading,
      isCapturingGps: isCapturingGps ?? this.isCapturingGps,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      sesionActiva: clearSesion ? null : (sesionActiva ?? this.sesionActiva),
      location: location ?? this.location,
      ultimoResultado:
          clearResultado ? null : (ultimoResultado ?? this.ultimoResultado),
      colaOffline: colaOffline ?? this.colaOffline,
      error: clearError ? null : (error ?? this.error),
      semaforo: semaforo ?? this.semaforo,
      consentimientoRequerido:
          consentimientoRequerido ?? this.consentimientoRequerido,
      rechazosPorConsentimiento:
          rechazosPorConsentimiento ?? this.rechazosPorConsentimiento,
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
        colaOffline,
        error,
        semaforo,
        consentimientoRequerido,
        rechazosPorConsentimiento,
      ];
}
