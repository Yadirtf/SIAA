// asistencia_asignatura.dart — Porcentaje de asistencia del estudiante por asignatura
// (US-MAR-13 AC-05). Respuesta de GET /me/asistencia.
import 'package:equatable/equatable.dart';

class AsistenciaAsignatura extends Equatable {
  final String grupoId;
  final String grupo;
  final String asignaturaId;
  final String asignatura;
  final int sesionesDictadas;
  final int sesionesAsistidas;
  final double porcentaje;
  final int umbral;
  final bool bajoUmbral;

  const AsistenciaAsignatura({
    required this.grupoId,
    required this.grupo,
    required this.asignaturaId,
    required this.asignatura,
    required this.sesionesDictadas,
    required this.sesionesAsistidas,
    required this.porcentaje,
    required this.umbral,
    required this.bajoUmbral,
  });

  bool get sinClases => sesionesDictadas == 0;

  /// "87,5 %" con coma decimal (es-CO); sin decimal cuando es entero.
  String get porcentajeTexto {
    final entero = porcentaje == porcentaje.roundToDouble();
    final texto = entero
        ? porcentaje.toStringAsFixed(0)
        : porcentaje.toStringAsFixed(1).replaceAll('.', ',');
    return '$texto %';
  }

  factory AsistenciaAsignatura.fromJson(Map<String, dynamic> j) =>
      AsistenciaAsignatura(
        grupoId: j['grupoId'] as String? ?? '',
        grupo: j['grupo'] as String? ?? '',
        asignaturaId: j['asignaturaId'] as String? ?? '',
        asignatura: j['asignatura'] as String? ?? 'Asignatura',
        sesionesDictadas: (j['sesionesDictadas'] as num?)?.toInt() ?? 0,
        sesionesAsistidas: (j['sesionesAsistidas'] as num?)?.toInt() ?? 0,
        porcentaje: (j['porcentaje'] as num?)?.toDouble() ?? 0,
        umbral: (j['umbral'] as num?)?.toInt() ?? 0,
        bajoUmbral: j['bajoUmbral'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        grupoId,
        grupo,
        asignaturaId,
        asignatura,
        sesionesDictadas,
        sesionesAsistidas,
        porcentaje,
        umbral,
        bajoUmbral,
      ];
}
