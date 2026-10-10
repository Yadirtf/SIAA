// geometria_exceptions.dart — Errores tipados al guardar geometría (US-GEO-05, US-GEO-10)
import 'package:dio/dio.dart';

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

/// La geometría cambió en el servidor después de leerla (409 CONFLICTO_VERSION).
class ConflictoVersionGeometriaException implements Exception {
  final String mensaje;

  ConflictoVersionGeometriaException(this.mensaje);

  @override
  String toString() => mensaje;
}

/// Traduce la respuesta de error de PUT /espacios/:id/geometria a una excepción tipada.
Exception excepcionGuardadoGeometria(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    final codigo = data['codigo'] as String?;
    final mensaje = data['mensaje'] as String? ?? 'Error al guardar geometría';
    final detalles = (data['detalles'] as List<dynamic>?)
        ?.map((d) => d is Map<String, dynamic>
            ? d['error']?.toString() ?? ''
            : d.toString())
        .toList();
    if (codigo == 'VALIDACION' &&
        mensaje.toLowerCase().contains('solapamiento')) {
      return SolapamientoAdvertenciaException(
          mensaje: mensaje, detalles: detalles);
    }
    if (codigo == 'GEOMETRIA_SOLAPADA') {
      return SolapamientoCriticoException(mensaje: mensaje);
    }
    if (codigo == 'CONFLICTO_VERSION') {
      return ConflictoVersionGeometriaException(mensaje);
    }
    return Exception(mensaje);
  }
  return Exception(e.response?.data?.toString() ??
      e.message ??
      'Error de red o servidor inalcanzable. Detalles: ${e.toString()}');
}
