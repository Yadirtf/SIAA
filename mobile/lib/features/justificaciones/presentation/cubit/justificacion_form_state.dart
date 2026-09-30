// justificacion_form_state.dart — Estado del formulario de radicación (US-JUS-01)
import 'package:equatable/equatable.dart';

import '../../domain/models/catalogo_justificacion.dart';
import '../../domain/models/justificacion_model.dart';
import '../../domain/models/soporte_adjunto.dart';

enum EnvioJustificacion { editando, adjuntando, enviando, exito }

class JustificacionFormState extends Equatable {
  final String sesionId;
  final TipoJustificacion? tipo;
  final List<SoporteAdjunto> soportes;
  final EnvioJustificacion envio;
  final String? error;
  final Justificacion? radicada;

  const JustificacionFormState({
    required this.sesionId,
    this.tipo,
    this.soportes = const [],
    this.envio = EnvioJustificacion.editando,
    this.error,
    this.radicada,
  });

  bool get enviando => envio == EnvioJustificacion.enviando;
  bool get ocupado => enviando || envio == EnvioJustificacion.adjuntando;
  bool get puedeAdjuntar =>
      !ocupado && soportes.length < ReglasSoporte.maxArchivos;

  /// Copia el estado; [error] siempre se reemplaza (se limpia si se omite).
  JustificacionFormState copyWith({
    TipoJustificacion? tipo,
    List<SoporteAdjunto>? soportes,
    EnvioJustificacion? envio,
    String? error,
    Justificacion? radicada,
  }) {
    return JustificacionFormState(
      sesionId: sesionId,
      tipo: tipo ?? this.tipo,
      soportes: soportes ?? this.soportes,
      envio: envio ?? this.envio,
      error: error,
      radicada: radicada ?? this.radicada,
    );
  }

  @override
  List<Object?> get props => [sesionId, tipo, soportes, envio, error, radicada];
}
