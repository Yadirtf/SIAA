import 'package:equatable/equatable.dart';

/// Cumplimiento agregado de un docente (o los totales del reporte).
class FilaCumplimientoModel extends Equatable {
  final String docenteId;
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
  final int ajustadas;

  /// Clases dictadas con salida OBLIGATORIA sin marcaje de salida (US-MAR-15).
  final int salidasFaltantes;

  /// Cumplimiento por debajo del umbral de alerta (US-PAR-04 AC-01).
  final bool bajoUmbral;
  final double porcentajeCumplimiento;

  const FilaCumplimientoModel({
    this.docenteId = '',
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
    this.ajustadas = 0,
    this.salidasFaltantes = 0,
    this.bajoUmbral = false,
    this.porcentajeCumplimiento = 0,
  });

  factory FilaCumplimientoModel.fromJson(Map<String, dynamic> json) {
    int entero(String k) => (json[k] as num?)?.toInt() ?? 0;
    double real(String k) => (json[k] as num?)?.toDouble() ?? 0;
    return FilaCumplimientoModel(
      docenteId: json['docenteId']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      documento: json['documento']?.toString() ?? '',
      sesiones: entero('sesiones'),
      horasProgramadas: real('horasProgramadas'),
      horasDictadas: real('horasDictadas'),
      horasJustificadas: real('horasJustificadas'),
      presentes: entero('presentes'),
      tardanzas: entero('tardanzas'),
      ausenciasJustificadas: entero('ausenciasJustificadas'),
      ausenciasInjustificadas: entero('ausenciasInjustificadas'),
      ajustadas: entero('ajustadas'),
      salidasFaltantes: entero('salidasFaltantes'),
      bajoUmbral: json['bajoUmbral'] == true,
      porcentajeCumplimiento: real('porcentajeCumplimiento'),
    );
  }

  @override
  List<Object?> get props => [
    docenteId,
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
    ajustadas,
    salidasFaltantes,
    bajoUmbral,
    porcentajeCumplimiento,
  ];
}
