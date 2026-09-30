import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Registro inmutable de la bitácora de auditoría (RF-AUD-003).
class EntradaAuditoriaModel extends Equatable {
  final String id;
  final String entidad;
  final String entidadId;
  final String accion;
  final String actorId;
  final String actorNombre;
  final String? rolActivo;
  final String? correlationId;
  final String? ipOrigen;
  final String? agenteUsuario;

  /// Estado previo y posterior; JSON arbitrario (mapa, lista o escalar).
  final Object? valorAnterior;
  final Object? valorNuevo;
  final DateTime? creadoEn;

  const EntradaAuditoriaModel({
    required this.id,
    required this.entidad,
    required this.entidadId,
    required this.accion,
    required this.actorId,
    this.actorNombre = '',
    this.rolActivo,
    this.correlationId,
    this.ipOrigen,
    this.agenteUsuario,
    this.valorAnterior,
    this.valorNuevo,
    this.creadoEn,
  });

  /// Nombre del actor, o su id si el backend no lo resolvió.
  String get actor => actorNombre.isNotEmpty ? actorNombre : actorId;

  /// JSON indentado para mostrar un valor, o null si no hay valor.
  static String? jsonLegible(Object? valor) {
    if (valor == null) return null;
    return const JsonEncoder.withIndent('  ').convert(valor);
  }

  factory EntradaAuditoriaModel.fromJson(Map<String, dynamic> json) {
    String? opcional(String k) {
      final v = json[k]?.toString();
      return v == null || v.isEmpty ? null : v;
    }

    return EntradaAuditoriaModel(
      id: json['id']?.toString() ?? '',
      entidad: json['entidad']?.toString() ?? '',
      entidadId: json['entidadId']?.toString() ?? '',
      accion: json['accion']?.toString() ?? '',
      actorId: json['actorId']?.toString() ?? '',
      actorNombre: json['actorNombre']?.toString() ?? '',
      rolActivo: opcional('rolActivo'),
      correlationId: opcional('correlationId'),
      ipOrigen: opcional('ipOrigen'),
      agenteUsuario: opcional('agenteUsuario'),
      valorAnterior: json['valorAnterior'],
      valorNuevo: json['valorNuevo'],
      creadoEn: DateTime.tryParse(json['creadoEn']?.toString() ?? '')
          ?.toLocal(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    entidad,
    entidadId,
    accion,
    actorId,
    actorNombre,
    rolActivo,
    correlationId,
    ipOrigen,
    agenteUsuario,
    jsonLegible(valorAnterior),
    jsonLegible(valorNuevo),
    creadoEn,
  ];
}
