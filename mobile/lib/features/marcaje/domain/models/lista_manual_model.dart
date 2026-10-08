// lista_manual_model.dart — Estudiantes del grupo y resultado del pase de lista manual (US-MAR-14)
import 'package:equatable/equatable.dart';

class EstudianteListaManual extends Equatable {
  final String id;
  final String nombre;
  final String correo;

  /// Resultado actual (PRESENTE, TARDANZA, AUSENTE, RECHAZADO_...), si existe.
  final String? resultado;

  /// Origen del registro actual (APP_MOVIL, MANUAL_DOCENTE, ...), si existe.
  final String? origen;

  /// Ya tiene un registro válido que la lista manual no sobrescribe (AC-04).
  final bool bloqueado;

  const EstudianteListaManual({
    required this.id,
    required this.nombre,
    this.correo = '',
    this.resultado,
    this.origen,
    this.bloqueado = false,
  });

  factory EstudianteListaManual.fromJson(Map<String, dynamic> json) {
    String? texto(String k) {
      final v = json[k];
      return v is String && v.isNotEmpty ? v : null;
    }

    return EstudianteListaManual(
      id: json['id'] as String? ?? '',
      nombre: texto('nombre') ?? 'Estudiante',
      correo: json['correo'] as String? ?? '',
      resultado: texto('resultado'),
      origen: texto('origen'),
      bloqueado: json['bloqueado'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, nombre, correo, resultado, origen, bloqueado];
}

class ResultadoListaManual extends Equatable {
  final String mensaje;
  final int registrados;
  final int conservados;
  final List<String> noPertenecen;

  const ResultadoListaManual({
    required this.mensaje,
    required this.registrados,
    required this.conservados,
    this.noPertenecen = const [],
  });

  factory ResultadoListaManual.fromJson(Map<String, dynamic> json) {
    return ResultadoListaManual(
      mensaje: json['mensaje'] as String? ?? 'Lista manual registrada.',
      registrados: (json['registrados'] as num?)?.toInt() ?? 0,
      conservados: (json['conservados'] as num?)?.toInt() ?? 0,
      noPertenecen: (json['noPertenecen'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  @override
  List<Object?> get props => [mensaje, registrados, conservados, noPertenecen];
}
