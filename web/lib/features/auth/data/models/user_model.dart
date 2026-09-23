import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String correo;
  final String nombre;
  final String apellido;
  final List<String> roles;
  final List<String> permisos;

  const UserModel({
    required this.id,
    required this.correo,
    required this.nombre,
    required this.apellido,
    required this.roles,
    required this.permisos,
  });

  String get fullName => '$nombre $apellido'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      apellido: json['apellido']?.toString() ?? '',
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      permisos: (json['permisos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'correo': correo,
      'nombre': nombre,
      'apellido': apellido,
      'roles': roles,
      'permisos': permisos,
    };
  }

  bool hasPermission(String permission) => permisos.contains(permission);
  bool hasRole(String role) => roles.contains(role);

  @override
  List<Object?> get props => [id, correo, nombre, apellido, roles, permisos];
}
