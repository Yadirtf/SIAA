import 'package:equatable/equatable.dart';

import 'lectura_json.dart';

/// Acumulado de un estudiante del grupo (US-REP-05 AC-01).
class FilaEstudianteModel extends Equatable {
  final String estudianteId;
  final String nombre;
  final String documento;
  final int sesionesDictadas;
  final int sesionesAsistidas;
  final double porcentaje;
  final bool bajoUmbral;

  const FilaEstudianteModel({
    required this.estudianteId,
    this.nombre = '',
    this.documento = '',
    this.sesionesDictadas = 0,
    this.sesionesAsistidas = 0,
    this.porcentaje = 0,
    this.bajoUmbral = false,
  });

  factory FilaEstudianteModel.fromJson(Map<String, dynamic> j) =>
      FilaEstudianteModel(
        estudianteId: jsonTexto(j['estudianteId']),
        nombre: jsonTexto(j['nombre']),
        documento: jsonTexto(j['documento']),
        sesionesDictadas: jsonEntero(j['sesionesDictadas']),
        sesionesAsistidas: jsonEntero(j['sesionesAsistidas']),
        porcentaje: jsonDecimal(j['porcentaje']),
        bajoUmbral: j['bajoUmbral'] == true,
      );

  @override
  List<Object?> get props => [estudianteId, porcentaje, bajoUmbral];
}

/// Resultado de GET /reportes/asistencia-estudiantil.
class ReporteAsistenciaGrupoModel extends Equatable {
  final String grupoId;
  final String grupo;
  final String asignatura;
  final int umbral;
  final int sesionesDictadas;
  final double promedioGrupo;
  final int estudiantesBajoUmbral;
  final List<FilaEstudianteModel> estudiantes;
  final DateTime? generadoEn;

  const ReporteAsistenciaGrupoModel({
    required this.grupoId,
    this.grupo = '',
    this.asignatura = '',
    this.umbral = 80,
    this.sesionesDictadas = 0,
    this.promedioGrupo = 0,
    this.estudiantesBajoUmbral = 0,
    this.estudiantes = const [],
    this.generadoEn,
  });

  factory ReporteAsistenciaGrupoModel.fromJson(Map<String, dynamic> j) =>
      ReporteAsistenciaGrupoModel(
        grupoId: jsonTexto(j['grupoId']),
        grupo: jsonTexto(j['grupo']),
        asignatura: jsonTexto(j['asignatura']),
        umbral: jsonEntero(j['umbral']),
        sesionesDictadas: jsonEntero(j['sesionesDictadas']),
        promedioGrupo: jsonDecimal(j['promedioGrupo']),
        estudiantesBajoUmbral: jsonEntero(j['estudiantesBajoUmbral']),
        estudiantes: jsonLista(j['estudiantes'])
            .map(FilaEstudianteModel.fromJson)
            .toList(),
        generadoEn: jsonFecha(j['generadoEn']),
      );

  @override
  List<Object?> get props => [grupoId, promedioGrupo, estudiantes];
}

/// Grupo que el usuario puede consultar (selector del reporte).
class GrupoReporteModel extends Equatable {
  final String grupoId;
  final String grupo;
  final String asignatura;

  const GrupoReporteModel({
    required this.grupoId,
    this.grupo = '',
    this.asignatura = '',
  });

  factory GrupoReporteModel.fromJson(Map<String, dynamic> j) =>
      GrupoReporteModel(
        grupoId: jsonTexto(j['grupoId']),
        grupo: jsonTexto(j['grupo']),
        asignatura: jsonTexto(j['asignatura']),
      );

  /// Texto del selector: "Cálculo · Grupo 01".
  String get etiqueta =>
      '${asignatura.isEmpty ? grupoId : asignatura} · Grupo $grupo';

  @override
  List<Object?> get props => [grupoId, grupo, asignatura];
}
