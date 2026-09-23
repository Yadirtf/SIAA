// Modelo de dominio para Bloque (US-GEO-01)
class BloqueModel {
  final String id;
  final String sedeId;
  final String codigo;
  final String nombre;
  final List<int> pisos;

  const BloqueModel({
    required this.id,
    required this.sedeId,
    required this.codigo,
    required this.nombre,
    required this.pisos,
  });

  factory BloqueModel.fromJson(Map<String, dynamic> json) {
    final pisosList = (json['pisos'] as List<dynamic>?)
            ?.map((p) => p is int ? p : int.tryParse(p.toString()) ?? 1)
            .toList() ??
        [1];
    return BloqueModel(
      id: json['id'] as String? ?? '',
      sedeId: json['sedeId'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      pisos: pisosList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sedeId': sedeId,
    'codigo': codigo,
    'nombre': nombre,
    'pisos': pisos,
  };
}
