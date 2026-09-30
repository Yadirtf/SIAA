import 'package:equatable/equatable.dart';

/// Criterios del reporte de cumplimiento. El backend exige un periodo o
/// un rango de fechas completo (desde y hasta).
class FiltroReporteModel extends Equatable {
  final String? periodoId;
  final String? facultadId;
  final String? programaId;
  final String? docenteId;
  final String? desde;
  final String? hasta;

  const FiltroReporteModel({
    this.periodoId,
    this.facultadId,
    this.programaId,
    this.docenteId,
    this.desde,
    this.hasta,
  });

  static bool _lleno(String? v) => v != null && v.isNotEmpty;

  bool get esValido => _lleno(periodoId) || (_lleno(desde) && _lleno(hasta));

  /// Copia el filtro; los campos se pasan como funciones para poder
  /// limpiarlos (p. ej. `programaId: () => null`).
  FiltroReporteModel copyWith({
    String? Function()? periodoId,
    String? Function()? facultadId,
    String? Function()? programaId,
    String? Function()? docenteId,
    String? Function()? desde,
    String? Function()? hasta,
  }) {
    return FiltroReporteModel(
      periodoId: periodoId != null ? periodoId() : this.periodoId,
      facultadId: facultadId != null ? facultadId() : this.facultadId,
      programaId: programaId != null ? programaId() : this.programaId,
      docenteId: docenteId != null ? docenteId() : this.docenteId,
      desde: desde != null ? desde() : this.desde,
      hasta: hasta != null ? hasta() : this.hasta,
    );
  }

  factory FiltroReporteModel.fromJson(Map<String, dynamic> json) {
    String? v(String k) {
      final s = json[k]?.toString();
      return _lleno(s) ? s : null;
    }

    return FiltroReporteModel(
      periodoId: v('periodoId'),
      facultadId: v('facultadId'),
      programaId: v('programaId'),
      docenteId: v('docenteId'),
      desde: v('desde'),
      hasta: v('hasta'),
    );
  }

  /// Parámetros de consulta (solo los que tienen valor).
  Map<String, String> toQuery() => {
    if (_lleno(periodoId)) 'periodoId': periodoId!,
    if (_lleno(facultadId)) 'facultadId': facultadId!,
    if (_lleno(programaId)) 'programaId': programaId!,
    if (_lleno(docenteId)) 'docenteId': docenteId!,
    if (_lleno(desde)) 'desde': desde!,
    if (_lleno(hasta)) 'hasta': hasta!,
  };

  @override
  List<Object?> get props => [
    periodoId,
    facultadId,
    programaId,
    docenteId,
    desde,
    hasta,
  ];
}
