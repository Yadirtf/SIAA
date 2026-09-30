// justificacion_model.dart — Justificación radicada por el docente (EP-07)
import 'package:equatable/equatable.dart';

import 'catalogo_justificacion.dart';

/// Metadatos de un soporte almacenado en el servidor.
class AdjuntoJustificacion extends Equatable {
  final String id;
  final String nombre;
  final String mime;
  final int tamano;
  final String sha256;

  const AdjuntoJustificacion({
    required this.id,
    required this.nombre,
    required this.mime,
    required this.tamano,
    required this.sha256,
  });

  bool get esPdf => mime == 'application/pdf';

  factory AdjuntoJustificacion.fromJson(Map<String, dynamic> json) =>
      AdjuntoJustificacion(
        id: json['id'] as String? ?? '',
        nombre: json['nombre'] as String? ?? '',
        mime: json['mime'] as String? ?? '',
        tamano: (json['tamano'] as num?)?.toInt() ?? 0,
        sha256: json['sha256'] as String? ?? '',
      );

  @override
  List<Object?> get props => [id, nombre, mime, tamano, sha256];
}

/// Entrada del historial de transiciones de estado.
class EventoJustificacion extends Equatable {
  final String estado;
  final String actorId;
  final String? observaciones;
  final DateTime? en;

  const EventoJustificacion({
    required this.estado,
    required this.actorId,
    this.observaciones,
    this.en,
  });

  factory EventoJustificacion.fromJson(Map<String, dynamic> json) =>
      EventoJustificacion(
        estado: json['estado'] as String? ?? '',
        actorId: json['actorId'] as String? ?? '',
        observaciones: _textoOpcional(json['observaciones']),
        en: _fecha(json['en']),
      );

  @override
  List<Object?> get props => [estado, actorId, observaciones, en];
}

class Justificacion extends Equatable {
  final String id;
  final String sesionId;
  final String docenteId;
  final String tipo;
  final String descripcion;
  final String estado;
  final List<AdjuntoJustificacion> adjuntos;
  final String? revisorId;
  final String? observaciones;
  final List<EventoJustificacion> historial;
  final String fechaSesion;
  final String nombreSesion;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const Justificacion({
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
    this.fechaSesion = '',
    this.nombreSesion = '',
    this.creadoEn,
    this.actualizadoEn,
  });

  EstadoJustificacion? get estadoConocido =>
      EstadoJustificacion.desdeCodigo(estado);
  String get tipoEtiqueta => TipoJustificacion.etiquetaDe(tipo);
  String get estadoEtiqueta => EstadoJustificacion.etiquetaDe(estado);
  bool get estaCerrada =>
      estado == EstadoJustificacion.aprobada.codigo ||
      estado == EstadoJustificacion.rechazada.codigo;

  factory Justificacion.fromJson(Map<String, dynamic> json) => Justificacion(
        id: json['id'] as String? ?? '',
        sesionId: json['sesionId'] as String? ?? '',
        docenteId: json['docenteId'] as String? ?? '',
        tipo: json['tipo'] as String? ?? '',
        descripcion: json['descripcion'] as String? ?? '',
        estado: json['estado'] as String? ?? '',
        adjuntos: _lista(json['adjuntos'], AdjuntoJustificacion.fromJson),
        revisorId: _textoOpcional(json['revisorId']),
        observaciones: _textoOpcional(json['observaciones']),
        historial: _lista(json['historial'], EventoJustificacion.fromJson),
        fechaSesion: json['fechaSesion'] as String? ?? '',
        nombreSesion: json['nombreSesion'] as String? ?? '',
        creadoEn: _fecha(json['creadoEn']),
        actualizadoEn: _fecha(json['actualizadoEn']),
      );

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
        fechaSesion,
        nombreSesion,
        creadoEn,
        actualizadoEn,
      ];
}

/// Página de justificaciones con el total informado en X-Total-Count.
class PaginaJustificaciones extends Equatable {
  final List<Justificacion> items;
  final int total;

  const PaginaJustificaciones({required this.items, required this.total});

  @override
  List<Object?> get props => [items, total];
}

List<T> _lista<T>(Object? raw, T Function(Map<String, dynamic>) fromJson) {
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
}

String? _textoOpcional(Object? valor) {
  if (valor is! String || valor.trim().isEmpty) return null;
  return valor;
}

DateTime? _fecha(Object? valor) =>
    valor is String ? DateTime.tryParse(valor) : null;
