// Servicio de localización GPS en tiempo real para el dispositivo móvil
// Conecta geolocator con el modelo de dominio GpsReading (US-GEO-02, US-LEG-01)
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/gps_reading.dart';

enum EstadoPermisoUbicacion {
  concedido,
  servicioDesactivado,
  denegado,
  denegadoPermanentemente,
}

class GpsLocationService {
  StreamSubscription<Position>? _positionSubscription;

  /// Verifica y solicita permisos de ubicación en primer plano conforme a RN-005 (while in use only).
  Future<EstadoPermisoUbicacion> verificarYSolicitarPermiso() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return EstadoPermisoUbicacion.servicioDesactivado;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return EstadoPermisoUbicacion.denegado;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return EstadoPermisoUbicacion.denegadoPermanentemente;
      }

      return EstadoPermisoUbicacion.concedido;
    } catch (_) {
      return EstadoPermisoUbicacion.denegado;
    }
  }

  /// Retrocompatibilidad: retorna booleano simple.
  Future<bool> solicitarPermisoUbicacion() async {
    final estado = await verificarYSolicitarPermiso();
    return estado == EstadoPermisoUbicacion.concedido;
  }

  /// Abre la configuración de ubicación del sistema operativo para que el usuario la active.
  Future<bool> abrirAjustesUbicacion() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Abre los ajustes de la aplicación (útil cuando el permiso fue denegado permanentemente).
  Future<bool> abrirAjustesAplicacion() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Obtiene la posición actual inmediata del sensor GPS.
  Future<GpsReading?> obtenerPosicionActual() async {
    try {
      final estado = await verificarYSolicitarPermiso();
      if (estado != EstadoPermisoUbicacion.concedido) return null;

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

  /// Inicia la escucha continua de actualizaciones del sensor GPS solicitando permisos si es necesario.
  Future<EstadoPermisoUbicacion> escucharPosicionesConPermiso({
    required void Function(GpsReading reading) onReading,
    void Function(dynamic error)? onError,
  }) async {
    try {
      final estado = await verificarYSolicitarPermiso();
      if (estado != EstadoPermisoUbicacion.concedido) {
        return estado;
      }

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

      return EstadoPermisoUbicacion.concedido;
    } catch (e) {
      onError?.call(e);
      return EstadoPermisoUbicacion.denegado;
    }
  }

  /// Inicia la escucha continua de actualizaciones del sensor GPS (directo).
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
