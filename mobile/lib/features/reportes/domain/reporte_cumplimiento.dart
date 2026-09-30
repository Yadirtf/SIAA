// reporte_cumplimiento.dart — Reporte de cumplimiento docente (RF-REP-001)
// Respuesta de GET /reportes/cumplimiento: {filtro, generadoEn, docentes[], totales, falsosRechazos}.
import 'package:equatable/equatable.dart';

double _num(Object? v) => v is num ? v.toDouble() : 0;
int _int(Object? v) => v is num ? v.toInt() : 0;

class FilaCumplimiento extends Equatable {
  final String nombre;
  final String documento;
  final int sesiones;
  final double horasProgramadas;
  final double horasDictadas;
  final double horasJustificadas;
  final int presentes;
  final int tardanzas;
  final int ausenciasJustificadas;
  final int ausenciasInjustificadas;
  final double porcentajeCumplimiento;

  const FilaCumplimiento({
    this.nombre = '',
    this.documento = '',
    this.sesiones = 0,
    this.horasProgramadas = 0,
    this.horasDictadas = 0,
    this.horasJustificadas = 0,
    this.presentes = 0,
    this.tardanzas = 0,
    this.ausenciasJustificadas = 0,
    this.ausenciasInjustificadas = 0,
    this.porcentajeCumplimiento = 0,
  });

  factory FilaCumplimiento.fromJson(Map<String, dynamic> j) => FilaCumplimiento(
        nombre: (j['nombre'] as String? ?? '').trim(),
        documento: (j['documento'] as String? ?? '').trim(),
        sesiones: _int(j['sesiones']),
        horasProgramadas: _num(j['horasProgramadas']),
        horasDictadas: _num(j['horasDictadas']),
        horasJustificadas: _num(j['horasJustificadas']),
        presentes: _int(j['presentes']),
        tardanzas: _int(j['tardanzas']),
        ausenciasJustificadas: _int(j['ausenciasJustificadas']),
        ausenciasInjustificadas: _int(j['ausenciasInjustificadas']),
        porcentajeCumplimiento: _num(j['porcentajeCumplimiento']),
      );

  String get nombreVisible => nombre.isNotEmpty ? nombre : 'Docente sin nombre';

  @override
  List<Object?> get props => [
        nombre,
        documento,
        sesiones,
        horasProgramadas,
        horasDictadas,
        horasJustificadas,
        presentes,
        tardanzas,
        ausenciasJustificadas,
        ausenciasInjustificadas,
        porcentajeCumplimiento,
      ];
}

class ReporteCumplimiento extends Equatable {
  final List<FilaCumplimiento> docentes;
  final FilaCumplimiento totales;
  final int falsosRechazos;
  final DateTime? generadoEn;

  const ReporteCumplimiento({
    required this.docentes,
    required this.totales,
    this.falsosRechazos = 0,
    this.generadoEn,
  });

  factory ReporteCumplimiento.fromJson(Map<String, dynamic> j) {
    final docentes = (j['docentes'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(FilaCumplimiento.fromJson)
        .toList()
      ..sort((a, b) =>
          a.porcentajeCumplimiento.compareTo(b.porcentajeCumplimiento));
    return ReporteCumplimiento(
      docentes: docentes,
      totales: FilaCumplimiento.fromJson(
          j['totales'] as Map<String, dynamic>? ?? const {}),
      falsosRechazos: _int(j['falsosRechazos']),
      generadoEn: DateTime.tryParse(j['generadoEn'] as String? ?? ''),
    );
  }

  @override
  List<Object?> get props => [docentes, totales, falsosRechazos, generadoEn];
}

/// Periodo académico seleccionable (GET /periodos).
class PeriodoOpcion extends Equatable {
  final String id;
  final String nombre;

  const PeriodoOpcion({required this.id, required this.nombre});

  factory PeriodoOpcion.fromJson(Map<String, dynamic> j) {
    final codigo = (j['codigo'] as String? ?? '').trim();
    final nombre = (j['nombre'] as String? ?? '').trim();
    return PeriodoOpcion(
      id: j['id'] as String? ?? '',
      nombre:
          nombre.isNotEmpty ? nombre : (codigo.isNotEmpty ? codigo : 'Periodo'),
    );
  }

  @override
  List<Object?> get props => [id, nombre];
}
