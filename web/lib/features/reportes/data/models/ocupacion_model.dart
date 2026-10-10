import 'package:equatable/equatable.dart';

import 'lectura_json.dart';

/// Uso real de un aula, bloque o sede (US-REP-04 AC-01).
class FilaOcupacionModel extends Equatable {
  final String id;
  final String nombre;
  final String bloque;
  final String sede;
  final int espacios;
  final int sesiones;
  final int sesionesConfirmadas;
  final double horasProgramadas;
  final double horasConfirmadas;
  final double porcentajeUtilizacion;

  const FilaOcupacionModel({
    this.id = '',
    this.nombre = '',
    this.bloque = '',
    this.sede = '',
    this.espacios = 0,
    this.sesiones = 0,
    this.sesionesConfirmadas = 0,
    this.horasProgramadas = 0,
    this.horasConfirmadas = 0,
    this.porcentajeUtilizacion = 0,
  });

  factory FilaOcupacionModel.fromJson(Map<String, dynamic> j) =>
      FilaOcupacionModel(
        id: jsonTexto(j['id']),
        nombre: jsonTexto(j['nombre']),
        bloque: jsonTexto(j['bloque']),
        sede: jsonTexto(j['sede']),
        espacios: jsonEntero(j['espacios']),
        sesiones: jsonEntero(j['sesiones']),
        sesionesConfirmadas: jsonEntero(j['sesionesConfirmadas']),
        horasProgramadas: jsonDecimal(j['horasProgramadas']),
        horasConfirmadas: jsonDecimal(j['horasConfirmadas']),
        porcentajeUtilizacion: jsonDecimal(j['porcentajeUtilizacion']),
      );

  @override
  List<Object?> get props => [
    id,
    nombre,
    sesiones,
    sesionesConfirmadas,
    horasProgramadas,
    horasConfirmadas,
    porcentajeUtilizacion,
  ];
}

/// Resultado de GET /reportes/ocupacion.
class ReporteOcupacionModel extends Equatable {
  final String agrupacion;
  final DateTime? generadoEn;
  final List<FilaOcupacionModel> filas;
  final FilaOcupacionModel totales;

  const ReporteOcupacionModel({
    this.agrupacion = 'aula',
    this.generadoEn,
    this.filas = const [],
    this.totales = const FilaOcupacionModel(),
  });

  factory ReporteOcupacionModel.fromJson(Map<String, dynamic> j) {
    final agrupacion = jsonTexto(jsonMapa(j['filtro'])['agrupacion']);
    return ReporteOcupacionModel(
      agrupacion: agrupacion.isEmpty ? 'aula' : agrupacion,
      generadoEn: jsonFecha(j['generadoEn']),
      filas: jsonLista(j['filas']).map(FilaOcupacionModel.fromJson).toList(),
      totales: FilaOcupacionModel.fromJson(jsonMapa(j['totales'])),
    );
  }

  @override
  List<Object?> get props => [agrupacion, generadoEn, filas, totales];
}

/// Criterios del reporte de ocupación: periodo o rango completo, y agrupación.
class FiltroOcupacionModel extends Equatable {
  final String? periodoId;
  final String? desde;
  final String? hasta;
  final String agrupacion;

  const FiltroOcupacionModel({
    this.periodoId,
    this.desde,
    this.hasta,
    this.agrupacion = 'aula',
  });

  static bool _lleno(String? v) => v != null && v.isNotEmpty;

  bool get esValido => _lleno(periodoId) || (_lleno(desde) && _lleno(hasta));

  FiltroOcupacionModel copyWith({
    String? Function()? periodoId,
    String? Function()? desde,
    String? Function()? hasta,
    String? agrupacion,
  }) => FiltroOcupacionModel(
    periodoId: periodoId != null ? periodoId() : this.periodoId,
    desde: desde != null ? desde() : this.desde,
    hasta: hasta != null ? hasta() : this.hasta,
    agrupacion: agrupacion ?? this.agrupacion,
  );

  Map<String, String> toQuery() => {
    'agrupacion': agrupacion,
    if (_lleno(periodoId)) 'periodoId': periodoId!,
    if (_lleno(desde)) 'desde': desde!,
    if (_lleno(hasta)) 'hasta': hasta!,
  };

  @override
  List<Object?> get props => [periodoId, desde, hasta, agrupacion];
}
