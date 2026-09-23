// Modelo para las versiones históricas de geometría de un espacio.
// US-GEO-06 AC-04, T-GEO-06.4.

class GeometriaHistorialItem {
  final String id;
  final String espacioId;
  final int version;
  final List<List<double>> coordenadas; // [[lon, lat], ...]
  final double areaMetrosCuadrados;
  final String? metodoCaptura;
  final double? precisionPromedioMetros;
  final String creadoPor;
  final DateTime creadoEn;
  final String? motivoCambio;

  const GeometriaHistorialItem({
    required this.id,
    required this.espacioId,
    required this.version,
    required this.coordenadas,
    required this.areaMetrosCuadrados,
    this.metodoCaptura,
    this.precisionPromedioMetros,
    required this.creadoPor,
    required this.creadoEn,
    this.motivoCambio,
  });

  factory GeometriaHistorialItem.fromJson(Map<String, dynamic> json) {
    List<List<double>> coords = [];
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

    DateTime date;
    try {
      date = DateTime.parse(json['creadoEn'] as String);
    } catch (_) {
      date = DateTime.now();
    }

    return GeometriaHistorialItem(
      id: json['id'] as String? ?? '',
      espacioId: json['espacioId'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      coordenadas: coords,
      areaMetrosCuadrados: (json['areaMetrosCuadrados'] as num?)?.toDouble() ?? 0.0,
      metodoCaptura: json['metodoCaptura'] as String?,
      precisionPromedioMetros: (json['precisionPromedioMetros'] as num?)?.toDouble(),
      creadoPor: json['creadoPor'] as String? ?? 'Admin',
      creadoEn: date,
      motivoCambio: json['motivoCambio'] as String?,
    );
  }
}
