// Lectura individual de posición GPS.
// ADR-04: orden estricto de coordenadas [longitud, latitud].
// RF-GEO-002, T-GEO-02.1.
class GpsReading {
  final double longitude;
  final double latitude;
  final double accuracy;
  final DateTime timestamp;

  GpsReading({
    required this.longitude,
    required this.latitude,
    required this.accuracy,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().toUtc();

  /// Retorna las coordenadas en formato GeoJSON [longitud, latitud] (ADR-04).
  List<double> toCoordinates() => [longitude, latitude];

  @override
  String toString() =>
      'GpsReading(lon: $longitude, lat: $latitude, acc: ${accuracy}m)';
}
