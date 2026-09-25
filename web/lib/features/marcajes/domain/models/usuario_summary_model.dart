// usuario_summary_model.dart — Modelo resumido de usuario para selectores en UI (US-AUT-01, US-MAR-09)
import 'package:equatable/equatable.dart';

class UsuarioSummaryModel extends Equatable {
  final String id;
  final String correo;
  final String nombre;
  final String apellido;
  final List<String> roles;
  final bool activo;

  const UsuarioSummaryModel({
    required this.id,
    required this.correo,
    required this.nombre,
    required this.apellido,
    this.roles = const [],
    this.activo = true,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();
  String get rolPrincipal => roles.isNotEmpty ? roles.first : 'Usuario';
  String get etiquetaSelector => '$nombreCompleto ($correo) - $rolPrincipal';

  factory UsuarioSummaryModel.fromJson(Map<String, dynamic> json) {
    return UsuarioSummaryModel(
      id: json['id'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      apellido: json['apellido'] as String? ?? '',
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      activo: json['activo'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, correo, nombre, apellido, roles, activo];
}
