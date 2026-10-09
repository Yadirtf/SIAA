// derechos_state.dart — Estado de la pantalla de derechos del titular (US-LEG-02)
import 'package:equatable/equatable.dart';

import '../../domain/models/canal_derechos.dart';
import '../../domain/models/solicitud_derecho.dart';

class DerechosState extends Equatable {
  final bool cargando;
  final bool enviando;
  final CanalDerechos? canal;
  final List<SolicitudDerecho> solicitudes;
  final List<ElementoSupresion> evaluacion;
  final String? error;
  final String? mensaje;

  const DerechosState({
    this.cargando = false,
    this.enviando = false,
    this.canal,
    this.solicitudes = const [],
    this.evaluacion = const [],
    this.error,
    this.mensaje,
  });

  /// Indica si ya hay un caso del tipo dado esperando respuesta.
  bool tieneAbierta(String tipo) =>
      solicitudes.any((s) => s.tipo == tipo && s.abierta);

  DerechosState copyWith({
    bool? cargando,
    bool? enviando,
    CanalDerechos? canal,
    List<SolicitudDerecho>? solicitudes,
    List<ElementoSupresion>? evaluacion,
    String? error,
    String? mensaje,
    bool limpiarAvisos = false,
  }) =>
      DerechosState(
        cargando: cargando ?? this.cargando,
        enviando: enviando ?? this.enviando,
        canal: canal ?? this.canal,
        solicitudes: solicitudes ?? this.solicitudes,
        evaluacion: evaluacion ?? this.evaluacion,
        error: limpiarAvisos ? error : (error ?? this.error),
        mensaje: limpiarAvisos ? mensaje : (mensaje ?? this.mensaje),
      );

  @override
  List<Object?> get props =>
      [cargando, enviando, canal, solicitudes, evaluacion, error, mensaje];
}
