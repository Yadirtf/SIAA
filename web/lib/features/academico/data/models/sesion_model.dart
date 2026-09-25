import 'package:equatable/equatable.dart';

class SesionModel extends Equatable {
  final String id;
  final String periodoId;
  final String asignacionId;
  final String asignaturaId;
  final String grupoId;
  final List<String> docenteIds;
  final String espacioId;
  final String fecha;
  final String horaInicio;
  final String horaFin;
  final String inicioProgramado;
  final String finProgramado;
  final String estado;
  final String motivoCancelacion;

  const SesionModel({
    required this.id,
    required this.periodoId,
    required this.asignacionId,
    required this.asignaturaId,
    required this.grupoId,
    required this.docenteIds,
    required this.espacioId,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.inicioProgramado,
    required this.finProgramado,
    required this.estado,
    this.motivoCancelacion = '',
  });

  bool get esCancelada => estado.toUpperCase() == 'CANCELADA';

  factory SesionModel.fromJson(Map<String, dynamic> json) {
    final docs = (json['docenteIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return SesionModel(
      id: json['id']?.toString() ?? '',
      periodoId: json['periodoId']?.toString() ?? '',
      asignacionId: json['asignacionId']?.toString() ?? '',
      asignaturaId: json['asignaturaId']?.toString() ?? '',
      grupoId: json['grupoId']?.toString() ?? '',
      docenteIds: docs,
      espacioId: json['espacioId']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      horaInicio: json['horaInicio']?.toString() ?? '',
      horaFin: json['horaFin']?.toString() ?? '',
      inicioProgramado: json['inicioProgramado']?.toString() ?? '',
      finProgramado: json['finProgramado']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'PROGRAMADA',
      motivoCancelacion: json['motivoCancelacion']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        periodoId,
        asignacionId,
        asignaturaId,
        grupoId,
        docenteIds,
        espacioId,
        fecha,
        horaInicio,
        horaFin,
        estado,
        motivoCancelacion,
      ];
}
