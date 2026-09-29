import 'package:equatable/equatable.dart';

import 'ambito_model.dart';
import 'rol_asignado_model.dart';

/// Vista administrativa de un usuario (UsuarioDTO del backend).
class UsuarioModel extends Equatable {
  final String id;
  final String correo;
  final String nombre;
  final String apellido;
  final String? documento;
  final bool activo;
  final bool bloqueado;
  final bool totpActivado;
  final List<String> roles;
  final List<RolAsignadoModel> rolesDetalle;
  final List<AmbitoModel> ambitos;
  final DateTime? creadoEn;

  const UsuarioModel({
    required this.id,
    required this.correo,
    required this.nombre,
    required this.apellido,
    this.documento,
    required this.activo,
    this.bloqueado = false,
    this.totpActivado = false,
    this.roles = const [],
    this.rolesDetalle = const [],
    this.ambitos = const [],
    this.creadoEn,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  /// Estado legible: el bloqueo temporal prevalece sobre activo/inactivo.
  String get estadoTexto {
    if (bloqueado) return 'Bloqueado';
    return activo ? 'Activo' : 'Inactivo';
  }

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> mapas(dynamic v) => v is List
        ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : const [];

    final roles = json['roles'] is List
        ? (json['roles'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final detalle = mapas(json['rolesDetalle'])
        .map(RolAsignadoModel.fromJson)
        .toList();
    final documento = json['documento']?.toString();

    return UsuarioModel(
      id: json['id']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      documento: documento == null || documento.isEmpty ? null : documento,
      activo: json['activo'] == true,
      bloqueado: json['bloqueado'] == true,
      totpActivado: json['totpActivado'] == true,
      roles: roles.isEmpty ? detalle.map((r) => r.nombre).toList() : roles,
      rolesDetalle: detalle.isEmpty
          ? roles.map((r) => RolAsignadoModel(nombre: r)).toList()
          : detalle,
      ambitos: mapas(json['ambitos']).map(AmbitoModel.fromJson).toList(),
      creadoEn: DateTime.tryParse(json['creadoEn']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [
    id,
    correo,
    nombre,
    apellido,
    documento,
    activo,
    bloqueado,
    totpActivado,
    roles,
    rolesDetalle,
    ambitos,
    creadoEn,
  ];
}
