// horario_state.dart - Estado del BLoC de Mi Horario (US-ACA-01..09)
import 'package:equatable/equatable.dart';
import '../../data/models/sesion_horario_model.dart';

enum EstadoCargaHorario { inicial, cargando, listo, error }

class HorarioState extends Equatable {
  final EstadoCargaHorario estado;

  /// Lunes de la semana visible (a medianoche).
  final DateTime lunes;
  final DateTime diaSeleccionado;
  final Map<DateTime, List<SesionHorarioModel>> sesionesPorDia;
  final String? docenteId;
  final String? error;

  const HorarioState({
    required this.estado,
    required this.lunes,
    required this.diaSeleccionado,
    this.sesionesPorDia = const {},
    this.docenteId,
    this.error,
  });

  factory HorarioState.inicial(DateTime hoy) {
    final dia = diaLectivoDe(hoy);
    return HorarioState(
      estado: EstadoCargaHorario.inicial,
      lunes: lunesDe(dia),
      diaSeleccionado: dia,
    );
  }

  List<SesionHorarioModel> get sesionesDelDia =>
      sesionesPorDia[diaSeleccionado] ?? const [];

  int sesionesEn(DateTime dia) =>
      sesionesPorDia[DateTime(dia.year, dia.month, dia.day)]?.length ?? 0;

  HorarioState copyWith({
    EstadoCargaHorario? estado,
    DateTime? lunes,
    DateTime? diaSeleccionado,
    Map<DateTime, List<SesionHorarioModel>>? sesionesPorDia,
    String? docenteId,
    String? error,
  }) {
    return HorarioState(
      estado: estado ?? this.estado,
      lunes: lunes ?? this.lunes,
      diaSeleccionado: diaSeleccionado ?? this.diaSeleccionado,
      sesionesPorDia: sesionesPorDia ?? this.sesionesPorDia,
      docenteId: docenteId ?? this.docenteId,
      error: error,
    );
  }

  /// Lunes (medianoche) de la semana de [f].
  static DateTime lunesDe(DateTime f) =>
      DateTime(f.year, f.month, f.day - (f.weekday - DateTime.monday));

  /// El domingo no es lectivo: se muestra el lunes siguiente.
  static DateTime diaLectivoDe(DateTime f) {
    final dia = DateTime(f.year, f.month, f.day);
    return f.weekday == DateTime.sunday
        ? dia.add(const Duration(days: 1))
        : dia;
  }

  @override
  List<Object?> get props =>
      [estado, lunes, diaSeleccionado, sesionesPorDia, docenteId, error];
}
