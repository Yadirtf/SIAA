import 'package:equatable/equatable.dart';

import '../../../academico/data/models/academico_models.dart';
import '../../data/models/asistencia_grupo_model.dart';

enum AsistenciaGrupoStatus { inicial, cargando, cargado, error }

class AsistenciaGrupoState extends Equatable {
  final AsistenciaGrupoStatus status;
  final List<PeriodoModel> periodos;
  final List<GrupoReporteModel> grupos;
  final String? periodoId;
  final String? grupoId;
  final ReporteAsistenciaGrupoModel? reporte;
  final String? error;

  const AsistenciaGrupoState({
    this.status = AsistenciaGrupoStatus.inicial,
    this.periodos = const [],
    this.grupos = const [],
    this.periodoId,
    this.grupoId,
    this.reporte,
    this.error,
  });

  AsistenciaGrupoState copyWith({
    AsistenciaGrupoStatus? status,
    List<PeriodoModel>? periodos,
    List<GrupoReporteModel>? grupos,
    String? Function()? periodoId,
    String? Function()? grupoId,
    ReporteAsistenciaGrupoModel? Function()? reporte,
    String? Function()? error,
  }) => AsistenciaGrupoState(
    status: status ?? this.status,
    periodos: periodos ?? this.periodos,
    grupos: grupos ?? this.grupos,
    periodoId: periodoId != null ? periodoId() : this.periodoId,
    grupoId: grupoId != null ? grupoId() : this.grupoId,
    reporte: reporte != null ? reporte() : this.reporte,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [
    status,
    periodos,
    grupos,
    periodoId,
    grupoId,
    reporte,
    error,
  ];
}
