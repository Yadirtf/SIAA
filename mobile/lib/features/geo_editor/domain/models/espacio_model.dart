// Modelo de dominio para Espacio / Aula (US-GEO-01, US-GEO-02)
class EspacioModel {
  final String id;
  final String sedeId;
  final String? bloqueId;
  final int? piso;
  final String codigo;
  final String nombre;
  final int capacidad;
  final String tipo;
  final String estado;
  final String nivelValidacion;
  final double bufferMetros;
  final double areaMetrosCuadrados;
  final bool tieneGeometria;
  final List<List<double>>? coordenadas;

  const EspacioModel({
    required this.id,
    required this.sedeId,
    this.bloqueId,
    this.piso,
    required this.codigo,
    required this.nombre,
    required this.capacidad,
    required this.tipo,
    required this.estado,
    required this.nivelValidacion,
    required this.bufferMetros,
    required this.areaMetrosCuadrados,
    required this.tieneGeometria,
    this.coordenadas,
  });

  factory EspacioModel.fromJson(Map<String, dynamic> json) {
    List<List<double>>? coords;
    final geo = json['geometria'] as Map<String, dynamic>?;
    if (geo != null && geo['coordinates'] is List) {
      final rings = geo['coordinates'] as List<dynamic>;
      if (rings.isNotEmpty && rings.first is List) {
        final ring = rings.first as List<dynamic>;
        coords = ring.map<List<double>>((pt) {
          final p = pt as List<dynamic>;
          return [
            (p[0] as num).toDouble(),
            (p[1] as num).toDouble(),
          ];
        }).toList();
      }
    }

    return EspacioModel(
      id: json['id'] as String? ?? '',
      sedeId: json['sedeId'] as String? ?? '',
      bloqueId: json['bloqueId'] as String?,
      piso: json['piso'] as int?,
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      capacidad: json['capacidad'] as int? ?? 0,
      tipo: json['tipo'] as String? ?? 'AULA',
      estado: json['estado'] as String? ?? 'ACTIVO',
      nivelValidacion: json['nivelValidacion'] as String? ?? 'AULA',
      bufferMetros: (json['bufferMetros'] as num?)?.toDouble() ?? 10.0,
      areaMetrosCuadrados: (json['areaMetrosCuadrados'] as num?)?.toDouble() ?? 0.0,
      tieneGeometria: coords != null && coords.isNotEmpty,
      coordenadas: coords,
    );
  }
}
