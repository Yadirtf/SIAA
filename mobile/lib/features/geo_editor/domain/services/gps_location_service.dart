// Servicio de localización GPS en tiempo real para el dispositivo móvil
// Conecta geolocator con el modelo de dominio GpsReading (US-GEO-02, US-LEG-01)
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/gps_reading.dart';

class GpsLocationService {
  StreamSubscription<Position>? _positionSubscription;

  /// Verifica y solicita permisos de ubicación en primer plano conforme a US-LEG-01.
  Future<bool> solicitarPermisoUbicacion() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Obtiene la posición actual inmediata.
  Future<GpsReading?> obtenerPosicionActual() async {
    try {
      final hasPermission = await solicitarPermisoUbicacion();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return GpsReading(
        longitude: position.longitude,
        latitude: position.latitude,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (_) {
      return null;
    }
  }

  /// Inicia la escucha continua de actualizaciones del sensor GPS.
  void escucharPosiciones({
    required void Function(GpsReading reading) onReading,
    void Function(dynamic error)? onError,
  }) {
    detenerEscucha();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (position) {
        onReading(GpsReading(
          longitude: position.longitude,
          latitude: position.latitude,
          accuracy: position.accuracy,
          timestamp: position.timestamp,
        ));
      },
      onError: onError,
    );
  }

  /// Cancela la suscripción al stream de GPS.
  void detenerEscucha() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
