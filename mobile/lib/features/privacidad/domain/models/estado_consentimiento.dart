// estado_consentimiento.dart — Decisión del usuario sobre el aviso vigente (US-LEG-01, CA-011)
// Espejo de GET/POST /me/consentimiento.
import 'package:equatable/equatable.dart';

class EstadoConsentimiento extends Equatable {
  static const aceptado = 'ACEPTADO';
  static const rechazado = 'RECHAZADO';

  final String versionVigente;

  /// true mientras no exista una aceptación sobre la versión vigente.
  final bool requiereAceptacion;

  /// ACEPTADO | RECHAZADO | null (sin decisión).
  final String? decision;
  final String? versionDecidida;
  final DateTime? decididoEn;

  const EstadoConsentimiento({
    required this.versionVigente,
    required this.requiereAceptacion,
    this.decision,
    this.versionDecidida,
    this.decididoEn,
  });

  factory EstadoConsentimiento.fromJson(Map<String, dynamic> json) {
    final decidido = json['decididoEn'];
    return EstadoConsentimiento(
      versionVigente: json['versionVigente'] as String? ?? '',
      requiereAceptacion: json['requiereAceptacion'] as bool? ?? true,
      decision: json['decision'] as String?,
      versionDecidida: json['versionDecidida'] as String?,
      decididoEn: decidido is String ? DateTime.tryParse(decidido) : null,
    );
  }

  /// Hay aceptación vigente: se permite pedir ubicación y marcar.
  bool get otorgado => !requiereAceptacion;

  /// El usuario rechazó explícitamente la versión vigente.
  bool get rechazadoVigente =>
      requiereAceptacion &&
      decision == rechazado &&
      versionDecidida == versionVigente;

  /// Se debe mostrar el aviso a pantalla completa: no hay decisión sobre la
  /// versión vigente (primer uso o nueva versión publicada).
  bool get debePreguntar => requiereAceptacion && !rechazadoVigente;

  @override
  List<Object?> get props => [
        versionVigente,
        requiereAceptacion,
        decision,
        versionDecidida,
        decididoEn
      ];
}
