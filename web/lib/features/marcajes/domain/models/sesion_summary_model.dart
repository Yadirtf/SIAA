// sesion_summary_model.dart — Modelo resumido de sesión académica para selectores en UI (US-ACA-05, US-MAR-09)
import 'package:equatable/equatable.dart';

class SesionSummaryModel extends Equatable {
  final String id;
  final String periodoId;
  final String asignaturaId;
  final String grupoId;
  final String espacioId;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final String estado;

  const SesionSummaryModel({
    required this.id,
    this.periodoId = '',
    this.asignaturaId = '',
    this.grupoId = '',
    this.espacioId = '',
    this.fecha = '',
    this.horaInicio = '',
    this.horaFin = '',
    this.estado = '',
  });

  String get etiquetaSelector {
    final cortaId = id.length > 6 ? id.substring(id.length - 6) : id;
    final horario = (horaInicio.isNotEmpty && horaFin.isNotEmpty) ? ' $horaInicio-$horaFin' : '';
    final f = fecha.isNotEmpty ? ' [$fecha$horario]' : '';
    return 'Sesión #$cortaId$f ($estado)';
  }

  factory SesionSummaryModel.fromJson(Map<String, dynamic> json) {
    return SesionSummaryModel(
      id: json['id'] as String? ?? '',
      periodoId: json['periodoId'] as String? ?? '',
      asignaturaId: json['asignaturaId'] as String? ?? '',
      grupoId: json['grupoId'] as String? ?? '',
      espacioId: json['espacioId'] as String? ?? '',
      fecha: json['fecha'] as String? ?? '',
      horaInicio: json['horaInicio'] as String? ?? '',
      horaFin: json['horaFin'] as String? ?? '',
      estado: json['estado'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, periodoId, asignaturaId, grupoId, espacioId, fecha, horaInicio, horaFin, estado];
}
