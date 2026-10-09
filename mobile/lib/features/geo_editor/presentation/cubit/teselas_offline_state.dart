// teselas_offline_state.dart — Estado del caché de teselas del modo mapa (US-GEO-03 AC-04)
import 'package:equatable/equatable.dart';

/// Qué parte del área visible está guardada en el dispositivo (solo se evalúa sin red).
enum CoberturaTeselas { desconocida, completa, parcial, ninguna }

class TeselasOfflineState extends Equatable {
  final bool enLinea;
  final CoberturaTeselas cobertura;
  final bool descargando;
  final int procesadas;
  final int total;

  /// Resultado de la última descarga o motivo por el que no se pudo hacer.
  final String? mensaje;

  /// Cambia con cada mensaje nuevo, para mostrarlo aunque el texto se repita.
  final int mensajeId;

  const TeselasOfflineState({
    this.enLinea = true,
    this.cobertura = CoberturaTeselas.desconocida,
    this.descargando = false,
    this.procesadas = 0,
    this.total = 0,
    this.mensaje,
    this.mensajeId = 0,
  });

  TeselasOfflineState copyWith({
    bool? enLinea,
    CoberturaTeselas? cobertura,
    bool? descargando,
    int? procesadas,
    int? total,
    String? mensaje,
    bool nuevoMensaje = false,
  }) {
    return TeselasOfflineState(
      enLinea: enLinea ?? this.enLinea,
      cobertura: cobertura ?? this.cobertura,
      descargando: descargando ?? this.descargando,
      procesadas: procesadas ?? this.procesadas,
      total: total ?? this.total,
      mensaje: nuevoMensaje ? mensaje : this.mensaje,
      mensajeId: nuevoMensaje ? mensajeId + 1 : mensajeId,
    );
  }

  @override
  List<Object?> get props =>
      [enLinea, cobertura, descargando, procesadas, total, mensaje, mensajeId];
}
