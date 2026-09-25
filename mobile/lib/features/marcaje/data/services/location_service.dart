// location_service.dart — Captura puntual de ubicación con validación de frescura y mock (US-MAR-02)
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitud;
  final double longitud;
  final double precisionMetros;
  final DateTime timestamp;
  final bool isMocked;
  final String? error;

  const LocationResult({
    required this.latitud,
    required this.longitud,
    required this.precisionMetros,
    required this.timestamp,
    required this.isMocked,
    this.error,
  });

  bool get hasError => error != null;
}

class LocationService {
  final GeolocatorPlatform _geolocator;

  LocationService({GeolocatorPlatform? geolocator})
      : _geolocator = geolocator ?? GeolocatorPlatform.instance;

  /// Obtiene una lectura puntual de GPS con proveedor fusionado y alta precisión.
  /// No mantiene rastreo continuo en segundo plano (RNF-SEG-004, US-MAR-02).
  Future<LocationResult> capturarUbicacionPuntual({
    Duration timeout = const Duration(seconds: 15),
    Duration antiguedadMaxima = const Duration(seconds: 30),
  }) async {
    final servicioHabilitado = await _geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      return LocationResult(
        latitud: 0,
        longitud: 0,
        precisionMetros: 0,
        timestamp: DateTime.now(),
        isMocked: false,
        error: 'El servicio de ubicación GPS se encuentra apagado en el dispositivo.',
      );
    }

    var permiso = await _geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await _geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        return LocationResult(
          latitud: 0,
          longitud: 0,
          precisionMetros: 0,
          timestamp: DateTime.now(),
          isMocked: false,
          error: 'Permiso de ubicación denegado por el usuario.',
        );
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      return LocationResult(
        latitud: 0,
        longitud: 0,
        precisionMetros: 0,
        timestamp: DateTime.now(),
        isMocked: false,
        error: 'Permiso de ubicación denegado permanentemente. Actívelo en Ajustes.',
      );
    }

    try {
      final posicion = await _geolocator
          .getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 15),
            ),
          )
          .timeout(timeout);

      // Descartar lectura si la antigüedad excede el umbral permitido (US-MAR-02 AC-02)
      final ahora = DateTime.now();
      final edad = ahora.difference(posicion.timestamp);
      if (edad > antiguedadMaxima) {
        return LocationResult(
          latitud: posicion.latitude,
          longitud: posicion.longitude,
          precisionMetros: posicion.accuracy,
          timestamp: posicion.timestamp,
          isMocked: posicion.isMocked,
          error: 'La lectura GPS es obsoleta (${edad.inSeconds}s de antigüedad). Reintente en un espacio abierto.',
        );
      }

      return LocationResult(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        precisionMetros: posicion.accuracy,
        timestamp: posicion.timestamp,
        isMocked: posicion.isMocked,
      );
    } on TimeoutException {
      return LocationResult(
        latitud: 0,
        longitud: 0,
        precisionMetros: 0,
        timestamp: DateTime.now(),
        isMocked: false,
        error: 'Tiempo de espera agotado al conectar con satélites GPS. Acérquese a una ventana o puerta.',
      );
    } catch (e) {
      return LocationResult(
        latitud: 0,
        longitud: 0,
        precisionMetros: 0,
        timestamp: DateTime.now(),
        isMocked: false,
        error: 'Error al capturar ubicación GPS: ${e.toString()}',
      );
    }
  }
}
