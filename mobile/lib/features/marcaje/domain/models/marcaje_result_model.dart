// marcaje_result_model.dart — Respuesta estructurada de evaluación en servidor
// Satisface US-MAR-03, US-MAR-06 y contrato §9.4.
import 'package:equatable/equatable.dart';

class MarcajeResultModel extends Equatable {
  final String? marcajeId;
  final String resultado; // ACEPTADO | RECHAZADO | PRECISION_INSUFICIENTE
  final String? motivoRechazo;
  final String mensaje;
  final double? distanciaMetros;
  final int minutosRespectoInicio;
  final double? precisionRecibida;
  final double? precisionRequerida;
  final String? timestampServidor;
  final int pasoFallido;
  final bool permiteReintento;
  final bool puedeJustificar;

  /// Minutos desde la entrada válida en una salida aceptada (US-MAR-15 AC-02).
  final int? permanenciaMin;

  const MarcajeResultModel({
    this.marcajeId,
    required this.resultado,
    this.motivoRechazo,
    required this.mensaje,
    this.distanciaMetros,
    this.minutosRespectoInicio = 0,
    this.precisionRecibida,
    this.precisionRequerida,
    this.timestampServidor,
    this.pasoFallido = 0,
    this.permiteReintento = false,
    this.puedeJustificar = false,
    this.permanenciaMin,
  });

  /// Resultados de aceptación: el motor devuelve PRESENTE/TARDANZA (y VALIDO/RETARDO heredados).
  static const resultadosAceptados = {
    'ACEPTADO',
    'PRESENTE',
    'TARDANZA',
    'VALIDO',
    'RETARDO',
  };

  bool get esAceptado => resultadosAceptados.contains(resultado);
  bool get esRechazado => resultado.startsWith('RECHAZADO');
  bool get esPrecisionInsuficiente => resultado == 'PRECISION_INSUFICIENTE';

  factory MarcajeResultModel.fromJson(Map<String, dynamic> json) {
    return MarcajeResultModel(
      marcajeId: json['marcajeId'] as String?,
      resultado: json['resultado'] as String? ?? 'RECHAZADO',
      motivoRechazo: json['motivoRechazo'] as String?,
      mensaje: json['mensaje'] as String? ?? '',
      distanciaMetros: (json['distanciaMetros'] as num?)?.toDouble(),
      minutosRespectoInicio:
          (json['minutosRespectoInicio'] as num?)?.toInt() ?? 0,
      precisionRecibida: (json['precisionRecibida'] as num?)?.toDouble(),
      precisionRequerida: (json['precisionRequerida'] as num?)?.toDouble(),
      timestampServidor: json['timestampServidor'] as String?,
      pasoFallido: (json['pasoFallido'] as num?)?.toInt() ?? 0,
      permiteReintento: json['permiteReintento'] as bool? ?? false,
      puedeJustificar: json['puedeJustificar'] as bool? ?? false,
      permanenciaMin: (json['permanenciaMin'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (marcajeId != null) 'marcajeId': marcajeId,
        'resultado': resultado,
        if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
        'mensaje': mensaje,
        if (distanciaMetros != null) 'distanciaMetros': distanciaMetros,
        'minutosRespectoInicio': minutosRespectoInicio,
        if (precisionRecibida != null) 'precisionRecibida': precisionRecibida,
        if (precisionRequerida != null)
          'precisionRequerida': precisionRequerida,
        if (timestampServidor != null) 'timestampServidor': timestampServidor,
        'pasoFallido': pasoFallido,
        'permiteReintento': permiteReintento,
        'puedeJustificar': puedeJustificar,
        if (permanenciaMin != null) 'permanenciaMin': permanenciaMin,
      };

  @override
  List<Object?> get props => [
        marcajeId,
        resultado,
        motivoRechazo,
        mensaje,
        distanciaMetros,
        minutosRespectoInicio,
        precisionRecibida,
        precisionRequerida,
        timestampServidor,
        pasoFallido,
        permiteReintento,
        puedeJustificar,
        permanenciaMin,
      ];
}
