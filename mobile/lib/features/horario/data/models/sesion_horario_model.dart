// sesion_horario_model.dart - Modelo de sesión para visualización de horario en mobile (US-ACA-01..09)
import 'package:equatable/equatable.dart';

class SesionHorarioModel extends Equatable {
  final String id;
  final String asignatura;
  final String grupo;
  final String espacio;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final String estado;
  final List<String> docentes;
  final String? motivoCancelacion;

  const SesionHorarioModel({
    required this.id,
    required this.asignatura,
    required this.grupo,
    required this.espacio,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    this.docentes = const [],
    this.motivoCancelacion,
  });

  bool get esCancelada => estado.toUpperCase() == 'CANCELADA';
  bool get enCurso => estado.toUpperCase() == 'EN_CURSO';
  bool get esProgramada => estado.toUpperCase() == 'PROGRAMADA';

  factory SesionHorarioModel.fromJson(Map<String, dynamic> json) {
    // Soporta formato DTO de /sesiones y /me/sesiones/hoy
    final id = (json['id'] ?? json['sesionId'] ?? '').toString();
    final asignatura = (json['asignatura'] ?? json['asignaturaId'] ?? 'Clase').toString();
    final grupo = (json['grupo'] ?? json['grupoId'] ?? 'G1').toString();
    
    String espacio = 'Aula';
    if (json['espacioCodigo'] != null) {
      espacio = json['espacioCodigo'].toString();
    } else if (json['espacioId'] != null) {
      espacio = json['espacioId'].toString();
    }

    DateTime fecha = DateTime.now();
    if (json['fecha'] != null) {
      fecha = DateTime.tryParse(json['fecha'].toString()) ?? fecha;
    } else if (json['inicioProgramado'] != null) {
      fecha = DateTime.tryParse(json['inicioProgramado'].toString()) ?? fecha;
    }

    String hInicio = '00:00';
    String hFin = '00:00';
    if (json['horaInicio'] != null && json['horaFin'] != null) {
      hInicio = json['horaInicio'].toString();
      hFin = json['horaFin'].toString();
    } else if (json['inicioProgramado'] != null && json['finProgramado'] != null) {
      final inicio = DateTime.tryParse(json['inicioProgramado'].toString());
      final fin = DateTime.tryParse(json['finProgramado'].toString());
      if (inicio != null && fin != null) {
        hInicio = '${inicio.toLocal().hour.toString().padLeft(2, '0')}:${inicio.toLocal().minute.toString().padLeft(2, '0')}';
        hFin = '${fin.toLocal().hour.toString().padLeft(2, '0')}:${fin.toLocal().minute.toString().padLeft(2, '0')}';
      }
    }

    final estado = (json['estado'] ?? 'PROGRAMADA').toString();
    final docentesList = (json['docenteIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return SesionHorarioModel(
      id: id,
      asignatura: asignatura,
      grupo: grupo,
      espacio: espacio,
      fecha: fecha,
      horaInicio: hInicio,
      horaFin: hFin,
      estado: estado,
      docentes: docentesList,
      motivoCancelacion: json['motivoCancelacion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'asignatura': asignatura,
        'grupo': grupo,
        'espacio': espacio,
        'fecha': fecha.toIso8601String(),
        'horaInicio': horaInicio,
        'horaFin': horaFin,
        'estado': estado,
        'docenteIds': docentes,
        'motivoCancelacion': motivoCancelacion,
      };

  @override
  List<Object?> get props => [
        id,
        asignatura,
        grupo,
        espacio,
        fecha,
        horaInicio,
        horaFin,
        estado,
        docentes,
        motivoCancelacion,
      ];
}
