import 'package:equatable/equatable.dart';

import '../../data/models/filtro_reporte_model.dart';
import '../../data/models/reporte_cumplimiento_model.dart';

enum ReporteStatus { inicial, cargando, cargado, error }

class ReporteCumplimientoState extends Equatable {
  final ReporteStatus status;
  final FiltroReporteModel filtro;
  final ReporteCumplimientoModel? reporte;
  final String? error;

  /// Formato en exportación (`xlsx`/`pdf`), o null si no se exporta.
  final String? exportando;
  final String? mensajeExito;
  final String? mensajeError;

  const ReporteCumplimientoState({
    this.status = ReporteStatus.inicial,
    this.filtro = const FiltroReporteModel(),
    this.reporte,
    this.error,
    this.exportando,
    this.mensajeExito,
    this.mensajeError,
  });

  ReporteCumplimientoState copyWith({
    ReporteStatus? status,
    FiltroReporteModel? filtro,
    ReporteCumplimientoModel? reporte,
    String? error,
    String? Function()? exportando,
    String? mensajeExito,
    String? mensajeError,
  }) {
    return ReporteCumplimientoState(
      status: status ?? this.status,
      filtro: filtro ?? this.filtro,
      reporte: reporte ?? this.reporte,
      error: error,
      exportando: exportando != null ? exportando() : this.exportando,
      mensajeExito: mensajeExito,
      mensajeError: mensajeError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    filtro,
    reporte,
    error,
    exportando,
    mensajeExito,
    mensajeError,
  ];
}
