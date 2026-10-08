import 'package:equatable/equatable.dart';

/// Resultado de POST /periodos/:id/generar-sesiones (US-ACA-05).
class InformeGeneracionModel extends Equatable {
  final int asignacionesProcesadas;
  final int sesionesGeneradas;
  final int sesionesOmitidasIdempotencia;

  /// Sesiones canceladas por una excepción ya eliminada que volvieron a programarse.
  final int sesionesReactivadas;
  final List<String> fechasExcluidas;
  final List<String> asignacionesOmitidas;
  final String mensaje;

  const InformeGeneracionModel({
    required this.asignacionesProcesadas,
    required this.sesionesGeneradas,
    required this.sesionesOmitidasIdempotencia,
    this.sesionesReactivadas = 0,
    required this.fechasExcluidas,
    required this.asignacionesOmitidas,
    required this.mensaje,
  });

  factory InformeGeneracionModel.fromJson(Map<String, dynamic> json) {
    List<String> lineas(String clave, String Function(Map) formato) {
      final lista = json[clave];
      if (lista is! List) return const [];
      return lista.whereType<Map>().map(formato).toList();
    }

    return InformeGeneracionModel(
      asignacionesProcesadas:
          (json['asignacionesProcesadas'] as num?)?.toInt() ?? 0,
      sesionesGeneradas: (json['sesionesGeneradas'] as num?)?.toInt() ?? 0,
      sesionesOmitidasIdempotencia:
          (json['sesionesOmitidasIdempotencia'] as num?)?.toInt() ?? 0,
      sesionesReactivadas: (json['sesionesReactivadas'] as num?)?.toInt() ?? 0,
      fechasExcluidas: lineas(
        'fechasExcluidas',
        (m) => '${m['fecha'] ?? ''}: ${m['motivo'] ?? ''}',
      ),
      asignacionesOmitidas: lineas(
        'asignacionesOmitidas',
        (m) => m['motivo']?.toString() ?? '',
      ),
      mensaje: json['mensaje']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
    asignacionesProcesadas,
    sesionesGeneradas,
    sesionesOmitidasIdempotencia,
    fechasExcluidas,
    asignacionesOmitidas,
    mensaje,
  ];
}
