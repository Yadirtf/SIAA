import 'package:equatable/equatable.dart';

/// Trabajo asíncrono del servidor (GET /trabajos/:id, US-ACA-05 AC-04).
class TrabajoModel extends Equatable {
  static const enProceso = 'EN_PROCESO';
  static const completado = 'COMPLETADO';
  static const fallido = 'FALLIDO';

  final String id;
  final String tipo;
  final String estado;
  final int progreso;

  /// Resultado del trabajo cuando terminó bien (p. ej. el informe).
  final Map<String, dynamic>? resultado;
  final String error;

  const TrabajoModel({
    required this.id,
    this.tipo = '',
    this.estado = enProceso,
    this.progreso = 0,
    this.resultado,
    this.error = '',
  });

  bool get terminado => estado == completado || estado == fallido;

  factory TrabajoModel.fromJson(Map<String, dynamic> json) => TrabajoModel(
    id: json['id']?.toString() ?? '',
    tipo: json['tipo']?.toString() ?? '',
    estado: json['estado']?.toString() ?? enProceso,
    progreso: (json['progreso'] as num?)?.toInt() ?? 0,
    resultado: json['resultado'] is Map
        ? Map<String, dynamic>.from(json['resultado'] as Map)
        : null,
    error: json['error']?.toString() ?? '',
  );

  @override
  List<Object?> get props => [id, tipo, estado, progreso, resultado, error];
}
