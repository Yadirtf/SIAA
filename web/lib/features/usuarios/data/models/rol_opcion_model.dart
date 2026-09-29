import 'package:equatable/equatable.dart';

/// Rol disponible en el sistema (GET /roles), para los selectores.
class RolOpcionModel extends Equatable {
  final String nombre;
  final String descripcion;
  final bool esPredefinido;

  const RolOpcionModel({
    required this.nombre,
    this.descripcion = '',
    this.esPredefinido = false,
  });

  factory RolOpcionModel.fromJson(Map<String, dynamic> json) {
    return RolOpcionModel(
      nombre: json['nombre']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      esPredefinido: json['esPredefinido'] == true,
    );
  }

  @override
  List<Object?> get props => [nombre, descripcion, esPredefinido];
}
