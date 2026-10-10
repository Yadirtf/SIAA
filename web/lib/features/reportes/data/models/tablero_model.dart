import 'package:equatable/equatable.dart';

import 'lectura_json.dart';

/// Sesión en curso a la que le falta la entrada del docente (US-REP-03 AC-03).
class SesionSinMarcajeModel extends Equatable {
  final String sesionId;
  final String docenteId;
  final String docente;
  final String aula;
  final String asignatura;
  final String horaInicio;
  final String horaFin;
  final int minutosTranscurridos;

  const SesionSinMarcajeModel({
    required this.sesionId,
    required this.docenteId,
    this.docente = '',
    this.aula = '',
    this.asignatura = '',
    this.horaInicio = '',
    this.horaFin = '',
    this.minutosTranscurridos = 0,
  });

  factory SesionSinMarcajeModel.fromJson(Map<String, dynamic> j) =>
      SesionSinMarcajeModel(
        sesionId: jsonTexto(j['sesionId']),
        docenteId: jsonTexto(j['docenteId']),
        docente: jsonTexto(j['docente']),
        aula: jsonTexto(j['aula']),
        asignatura: jsonTexto(j['asignatura']),
        horaInicio: jsonTexto(j['horaInicio']),
        horaFin: jsonTexto(j['horaFin']),
        minutosTranscurridos: jsonEntero(j['minutosTranscurridos']),
      );

  @override
  List<Object?> get props => [sesionId, docenteId, minutosTranscurridos];
}

/// Racha de inasistencias consecutivas aún abierta (US-PAR-04).
class AlertaActivaModel extends Equatable {
  final String docenteId;
  final String docente;
  final String mensaje;
  final DateTime? creadaEn;

  const AlertaActivaModel({
    required this.docenteId,
    this.docente = '',
    this.mensaje = '',
    this.creadaEn,
  });

  factory AlertaActivaModel.fromJson(Map<String, dynamic> j) =>
      AlertaActivaModel(
        docenteId: jsonTexto(j['docenteId']),
        docente: jsonTexto(j['docente']),
        mensaje: jsonTexto(j['mensaje']),
        creadaEn: jsonFecha(j['creadaEn']),
      );

  @override
  List<Object?> get props => [docenteId, mensaje, creadaEn];
}

/// Pulso del día dentro del ámbito del usuario (GET /reportes/tablero).
class TableroModel extends Equatable {
  final String fecha;
  final DateTime? generadoEn;
  final int sesionesDelDia;
  final int sesionesCanceladas;
  final int sesionesEnCurso;
  final int sesionesFinalizadas;
  final int entradasDocentes;
  final int salidasDocentes;
  final int entradasEstudiantes;
  final int marcajesTotal;
  final List<SesionSinMarcajeModel> sinMarcaje;
  final List<AlertaActivaModel> alertas;

  /// Intervalo base de actualización que sugiere el servidor.
  final int refrescoSugeridoSegundos;

  const TableroModel({
    this.fecha = '',
    this.generadoEn,
    this.sesionesDelDia = 0,
    this.sesionesCanceladas = 0,
    this.sesionesEnCurso = 0,
    this.sesionesFinalizadas = 0,
    this.entradasDocentes = 0,
    this.salidasDocentes = 0,
    this.entradasEstudiantes = 0,
    this.marcajesTotal = 0,
    this.sinMarcaje = const [],
    this.alertas = const [],
    this.refrescoSugeridoSegundos = 60,
  });

  factory TableroModel.fromJson(Map<String, dynamic> j) {
    final m = jsonMapa(j['marcajes']);
    final refresco = jsonEntero(j['refrescoSugeridoSegundos']);
    return TableroModel(
      fecha: jsonTexto(j['fecha']),
      generadoEn: jsonFecha(j['generadoEn']),
      sesionesDelDia: jsonEntero(j['sesionesDelDia']),
      sesionesCanceladas: jsonEntero(j['sesionesCanceladas']),
      sesionesEnCurso: jsonEntero(j['sesionesEnCurso']),
      sesionesFinalizadas: jsonEntero(j['sesionesFinalizadas']),
      entradasDocentes: jsonEntero(m['entradasDocentes']),
      salidasDocentes: jsonEntero(m['salidasDocentes']),
      entradasEstudiantes: jsonEntero(m['entradasEstudiantes']),
      marcajesTotal: jsonEntero(m['total']),
      sinMarcaje: jsonLista(j['sesionesEnCursoSinMarcaje'])
          .map(SesionSinMarcajeModel.fromJson)
          .toList(),
      alertas: jsonLista(j['alertasActivas'])
          .map(AlertaActivaModel.fromJson)
          .toList(),
      refrescoSugeridoSegundos: refresco > 0 ? refresco : 60,
    );
  }

  @override
  List<Object?> get props => [
    fecha,
    generadoEn,
    sesionesDelDia,
    sesionesEnCurso,
    marcajesTotal,
    sinMarcaje,
    alertas,
  ];
}
