import 'package:equatable/equatable.dart';

import '../../../academico/data/models/academico_models.dart';
import '../../data/models/ocupacion_model.dart';

enum OcupacionStatus { inicial, cargando, cargado, error }

class OcupacionState extends Equatable {
  final OcupacionStatus status;
  final FiltroOcupacionModel filtro;
  final ReporteOcupacionModel? reporte;
  final List<PeriodoModel> periodos;
  final String? error;

  /// Formato en exportación (`xlsx`/`pdf`), o null.
  final String? exportando;
  final String? mensajeExito;
  final String? mensajeError;

  const OcupacionState({
    this.status = OcupacionStatus.inicial,
    this.filtro = const FiltroOcupacionModel(),
    this.reporte,
    this.periodos = const [],
    this.error,
    this.exportando,
    this.mensajeExito,
    this.mensajeError,
  });

  /// Los mensajes son de un solo uso: no se copian.
  OcupacionState copyWith({
    OcupacionStatus? status,
    FiltroOcupacionModel? filtro,
    ReporteOcupacionModel? reporte,
    List<PeriodoModel>? periodos,
    String? Function()? error,
    String? Function()? exportando,
    String? mensajeExito,
    String? mensajeError,
  }) => OcupacionState(
    status: status ?? this.status,
    filtro: filtro ?? this.filtro,
    reporte: reporte ?? this.reporte,
    periodos: periodos ?? this.periodos,
    error: error != null ? error() : this.error,
    exportando: exportando != null ? exportando() : this.exportando,
    mensajeExito: mensajeExito,
    mensajeError: mensajeError,
  );

  @override
  List<Object?> get props => [
    status,
    filtro,
    reporte,
    periodos,
    error,
    exportando,
    mensajeExito,
    mensajeError,
  ];
}
