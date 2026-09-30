// consentimiento_state.dart — Estado del consentimiento informado (US-LEG-01)
import 'package:equatable/equatable.dart';
import '../../domain/models/estado_consentimiento.dart';
import '../../domain/models/politica_privacidad.dart';

enum FaseConsentimiento { inicial, cargando, listo, error }

class ConsentimientoState extends Equatable {
  final FaseConsentimiento fase;
  final EstadoConsentimiento? consentimiento;
  final PoliticaPrivacidad? politica;
  final bool enviando;
  final String? error;

  const ConsentimientoState({
    this.fase = FaseConsentimiento.inicial,
    this.consentimiento,
    this.politica,
    this.enviando = false,
    this.error,
  });

  /// Hay que mostrar el aviso a pantalla completa antes de continuar.
  bool get debePreguntar => consentimiento?.debePreguntar ?? false;

  bool get otorgado => consentimiento?.otorgado ?? false;

  bool get rechazado => consentimiento?.rechazadoVigente ?? false;

  /// Canal institucional indicado en el aviso (vacío si no se ha cargado).
  String get contacto => politica?.contacto ?? '';

  ConsentimientoState copyWith({
    FaseConsentimiento? fase,
    EstadoConsentimiento? consentimiento,
    PoliticaPrivacidad? politica,
    bool? enviando,
    String? error,
    bool limpiarError = false,
  }) {
    return ConsentimientoState(
      fase: fase ?? this.fase,
      consentimiento: consentimiento ?? this.consentimiento,
      politica: politica ?? this.politica,
      enviando: enviando ?? this.enviando,
      error: limpiarError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [fase, consentimiento, politica, enviando, error];
}
