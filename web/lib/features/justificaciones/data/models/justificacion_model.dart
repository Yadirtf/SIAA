import 'package:equatable/equatable.dart';

import 'adjunto_model.dart';
import 'transicion_model.dart';
import '../../../../core/utils/hora_12h.dart';

/// Novedad radicada por un docente sobre una sesión (EP-07).
class JustificacionModel extends Equatable {
  final String id;
  final String sesionId;
  final String docenteId;
  final String tipo;
  final String descripcion;
  final String estado;
  final List<AdjuntoModel> adjuntos;
  final String? revisorId;
  final String? observaciones;
  final List<TransicionModel> historial;
  final String? sedeId;
  final String? facultadId;
  final String fechaSesion;
  final String? nombreSesion;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const JustificacionModel({
    required this.id,
    required this.sesionId,
    required this.docenteId,
    required this.tipo,
    required this.descripcion,
    required this.estado,
    this.adjuntos = const [],
    this.revisorId,
    this.observaciones,
    this.historial = const [],
    this.sedeId,
    this.facultadId,
    this.fechaSesion = '',
    this.nombreSesion,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory JustificacionModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> mapas(dynamic v) => v is List
        ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];
    String? opcional(String clave) {
      final v = json[clave]?.toString();
      return v == null || v.isEmpty ? null : v;
    }

    DateTime? fecha(String clave) =>
        DateTime.tryParse(json[clave]?.toString() ?? '')?.toLocal();

    return JustificacionModel(
      id: json['id']?.toString() ?? '',
      sesionId: json['sesionId']?.toString() ?? '',
      docenteId: json['docenteId']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      estado: json['estado']?.toString() ?? '',
      adjuntos: mapas(json['adjuntos']).map(AdjuntoModel.fromJson).toList(),
      revisorId: opcional('revisorId'),
      observaciones: opcional('observaciones'),
      historial: mapas(json['historial'])
          .map(TransicionModel.fromJson)
          .toList(),
      sedeId: opcional('sedeId'),
      facultadId: opcional('facultadId'),
      fechaSesion: json['fechaSesion']?.toString() ?? '',
      nombreSesion: _horas12h(opcional('nombreSesion')),
      creadoEn: fecha('creadoEn'),
      actualizadoEn: fecha('actualizadoEn'),
    );
  }

  @override
  List<Object?> get props => [
    id,
    sesionId,
    docenteId,
    tipo,
    descripcion,
    estado,
    adjuntos,
    revisorId,
    observaciones,
    historial,
    sedeId,
    facultadId,
    fechaSesion,
    nombreSesion,
    creadoEn,
    actualizadoEn,
  ];
}

String? _horas12h(String? texto) =>
    texto == null ? null : horasEnTexto12h(texto);
