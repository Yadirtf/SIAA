import 'package:equatable/equatable.dart';

/// Rol asignado a un usuario, con su vigencia opcional.
class RolAsignadoModel extends Equatable {
  final String nombre;
  final DateTime? vigenciaInicio;
  final DateTime? vigenciaFin;

  const RolAsignadoModel({
    required this.nombre,
    this.vigenciaInicio,
    this.vigenciaFin,
  });

  factory RolAsignadoModel.fromJson(Map<String, dynamic> json) {
    return RolAsignadoModel(
      nombre: json['nombre']?.toString() ?? '',
      vigenciaInicio: DateTime.tryParse(
        json['vigenciaInicio']?.toString() ?? '',
      ),
      vigenciaFin: DateTime.tryParse(json['vigenciaFin']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    if (vigenciaInicio != null)
      'vigenciaInicio': vigenciaInicio!.toUtc().toIso8601String(),
    if (vigenciaFin != null)
      'vigenciaFin': vigenciaFin!.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [nombre, vigenciaInicio, vigenciaFin];
}
