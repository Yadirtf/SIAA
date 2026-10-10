import 'package:equatable/equatable.dart';

/// Estudiante matriculado en un grupo (US-MAR-13).
class EstudianteGrupo extends Equatable {
  final String id;
  final String nombre;
  final String correo;
  final String? documento;

  const EstudianteGrupo({
    required this.id,
    required this.nombre,
    required this.correo,
    this.documento,
  });

  factory EstudianteGrupo.fromJson(Map<String, dynamic> json) {
    final doc = json['documento']?.toString();
    return EstudianteGrupo(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      documento: (doc == null || doc.isEmpty) ? null : doc,
    );
  }

  /// Verdadero si [identificador] (id, correo o documento) corresponde a este estudiante.
  bool coincide(String identificador) {
    final v = identificador.trim().toLowerCase();
    return v == id.toLowerCase() ||
        v == correo.toLowerCase() ||
        (documento != null && v == documento!.toLowerCase());
  }

  @override
  List<Object?> get props => [id, nombre, correo, documento];
}

/// Respuesta del PUT: lista final del grupo e identificadores no aplicados.
class ResultadoEstudiantesGrupo extends Equatable {
  final List<EstudianteGrupo> estudiantes;
  final List<String> noEncontrados;
  final List<String> noEstudiantes;

  const ResultadoEstudiantesGrupo({
    required this.estudiantes,
    this.noEncontrados = const [],
    this.noEstudiantes = const [],
  });

  factory ResultadoEstudiantesGrupo.fromJson(Map<String, dynamic> json) {
    List<String> textos(String k) =>
        (json[k] as List? ?? const []).map((e) => e.toString()).toList();
    return ResultadoEstudiantesGrupo(
      estudiantes: (json['estudiantes'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EstudianteGrupo.fromJson)
          .toList(),
      noEncontrados: textos('noEncontrados'),
      noEstudiantes: textos('noEstudiantes'),
    );
  }

  @override
  List<Object?> get props => [estudiantes, noEncontrados, noEstudiantes];
}
