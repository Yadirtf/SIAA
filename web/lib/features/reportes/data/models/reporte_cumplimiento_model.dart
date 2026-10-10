import 'package:equatable/equatable.dart';

import 'fila_cumplimiento_model.dart';
import 'filtro_reporte_model.dart';

/// Resultado de GET /reportes/cumplimiento.
class ReporteCumplimientoModel extends Equatable {
  final FiltroReporteModel filtro;
  final DateTime? generadoEn;
  final List<FilaCumplimientoModel> docentes;
  final FilaCumplimientoModel totales;

  /// Justificaciones aprobadas por falla técnica en el periodo.
  final int falsosRechazos;

  /// Porcentaje mínimo de asistencia efectivo del ámbito: por debajo, la
  /// fila se marca `bajoUmbral` (US-PAR-04 AC-01).
  final double umbralAlerta;

  const ReporteCumplimientoModel({
    this.filtro = const FiltroReporteModel(),
    this.generadoEn,
    this.docentes = const [],
    this.totales = const FilaCumplimientoModel(),
    this.falsosRechazos = 0,
    this.umbralAlerta = 0,
  });

  factory ReporteCumplimientoModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> mapa(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    return ReporteCumplimientoModel(
      filtro: FiltroReporteModel.fromJson(mapa(json['filtro'])),
      generadoEn: DateTime.tryParse(json['generadoEn']?.toString() ?? '')
          ?.toLocal(),
      docentes: json['docentes'] is List
          ? (json['docentes'] as List)
                .whereType<Map>()
                .map((e) => FilaCumplimientoModel.fromJson(mapa(e)))
                .toList()
          : const [],
      totales: FilaCumplimientoModel.fromJson(mapa(json['totales'])),
      falsosRechazos: (json['falsosRechazos'] as num?)?.toInt() ?? 0,
      umbralAlerta: (json['umbralAlerta'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    filtro,
    generadoEn,
    docentes,
    totales,
    falsosRechazos,
    umbralAlerta,
  ];
}
