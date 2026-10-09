// geometria_exceptions.dart — Errores tipados al guardar geometría (US-GEO-05, US-GEO-10)

/// Excepción cuando un solapamiento <= 50% requiere confirmación del usuario (US-GEO-05 AC-01/AC-02).
class SolapamientoAdvertenciaException implements Exception {
  final String mensaje;
  final List<String>? detalles;

  SolapamientoAdvertenciaException({required this.mensaje, this.detalles});

  @override
  String toString() => mensaje;
}

/// Excepción cuando un solapamiento > 50% bloquea irrevocablemente el guardado (US-GEO-05 AC-03).
class SolapamientoCriticoException implements Exception {
  final String mensaje;

  SolapamientoCriticoException({required this.mensaje});

  @override
  String toString() => mensaje;
}

/// El servidor no respondió (sin red, DNS o tiempo agotado): la captura puede
/// guardarse en el dispositivo y sincronizarse después (US-GEO-10 AC-01).
class SinConexionGeometriaException implements Exception {
  final String mensaje;

  SinConexionGeometriaException(
      [this.mensaje = 'Sin conexión con el servidor.']);

  @override
  String toString() => mensaje;
}
