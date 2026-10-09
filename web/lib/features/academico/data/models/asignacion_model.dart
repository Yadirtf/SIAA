import 'package:equatable/equatable.dart';

import 'academico_models.dart' show textosDe;

/// Asignación horaria tal como la lista `GET /asignaciones` (US-ACA-03), con los
/// nombres de asignatura y grupo que resuelve el backend.
class AsignacionModel extends Equatable {
  final String id;
  final String periodoId;
  final List<String> docenteIds;
  final String docenteNombre;
  final String grupoId;
  final String grupoNumero;
  final String asignaturaId;
  final String asignaturaCodigo;
  final String asignaturaNombre;
  final String? espacioId;
  final String? espacioNombre;
  final int diaSemana;
  final String horaInicio;
  final String horaFin;
  final String modalidad;
  final String estado;

  /// Avisos no bloqueantes del guardado (franja muy corta, aula sin
  /// geometría…), US-ACA-03/04. Solo vienen en la respuesta de POST/PUT.
  final List<String> advertencias;

  const AsignacionModel({
    required this.id,
    required this.periodoId,
    this.docenteIds = const [],
    required this.docenteNombre,
    required this.grupoId,
    this.grupoNumero = '',
    required this.asignaturaId,
    this.asignaturaCodigo = '',
    this.asignaturaNombre = '',
    this.espacioId,
    this.espacioNombre,
    required this.diaSemana,
    required this.horaInicio,
    required this.horaFin,
    required this.modalidad,
    required this.estado,
    this.advertencias = const [],
  });

  factory AsignacionModel.fromJson(Map<String, dynamic> json) {
    final franja = json['franja'] as Map<String, dynamic>? ?? {};
    String texto(String clave) => json[clave]?.toString() ?? '';
    final espacio = texto('espacioId');
    final espacioNombre = texto('espacioNombre');
    return AsignacionModel(
      id: texto('id'),
      periodoId: texto('periodoId'),
      docenteIds: (json['docenteIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      docenteNombre: texto('docenteNombre'),
      grupoId: texto('grupoId'),
      grupoNumero: texto('grupoNumero'),
      asignaturaId: texto('asignaturaId'),
      asignaturaCodigo: texto('asignaturaCodigo'),
      asignaturaNombre: texto('asignaturaNombre'),
      espacioId: espacio.isEmpty ? null : espacio,
      espacioNombre: espacioNombre.isEmpty ? null : espacioNombre,
      diaSemana: (franja['diaSemana'] as num?)?.toInt() ?? 1,
      horaInicio: franja['horaInicio']?.toString() ?? '',
      horaFin: franja['horaFin']?.toString() ?? '',
      modalidad: json['modalidad']?.toString() ?? 'PRESENCIAL',
      estado: json['estado']?.toString() ?? 'PROPUESTA',
      advertencias: textosDe(json['advertencias']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    periodoId,
    docenteIds,
    docenteNombre,
    grupoId,
    grupoNumero,
    asignaturaId,
    asignaturaCodigo,
    asignaturaNombre,
    espacioId,
    espacioNombre,
    diaSemana,
    horaInicio,
    horaFin,
    modalidad,
    estado,
    advertencias,
  ];
}
