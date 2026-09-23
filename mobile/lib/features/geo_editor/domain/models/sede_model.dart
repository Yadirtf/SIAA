// Modelo de dominio para Sede (US-GEO-01)
class SedeModel {
  final String id;
  final String codigo;
  final String nombre;
  final String? direccion;

  const SedeModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    this.direccion,
  });

  factory SedeModel.fromJson(Map<String, dynamic> json) {
    return SedeModel(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'codigo': codigo,
    'nombre': nombre,
    if (direccion != null) 'direccion': direccion,
  };
}
