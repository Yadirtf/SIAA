// Modelo de vértice con trazabilidad de origen de captura.
// RF-GEO-004, US-GEO-03, ADR-04: [longitud, latitud].
enum OrigenVertice {
  gps,
  toqueMapa,
}

enum ModoCapturaEditor {
  recorrido,
  mapa,
}

class TaggedVertex {
  final double longitude;
  final double latitude;
  final OrigenVertice origen;
  final double? precision; // Precisión en metros (solo si origen == gps)
  final DateTime timestamp;

  TaggedVertex({
    required this.longitude,
    required this.latitude,
    required this.origen,
    this.precision,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  /// Retorna las coordenadas en formato GeoJSON [longitud, latitud] (ADR-04).
  List<double> toCoordinates() => [longitude, latitude];

  @override
  String toString() => 'TaggedVertex(lon: $longitude, lat: $latitude, origen: $origen, acc: $precision)';
}
