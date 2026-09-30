// consentimiento_requerido.dart — Error 403 CONSENTIMIENTO_REQUERIDO (US-LEG-01, CA-011)
// El backend rechaza cualquier creación de marcaje sin aceptación del aviso vigente.
import 'package:dio/dio.dart';

class ConsentimientoRequeridoException implements Exception {
  static const codigo = 'CONSENTIMIENTO_REQUERIDO';

  final String mensaje;

  const ConsentimientoRequeridoException([
    this.mensaje =
        'Debe aceptar el aviso de privacidad para registrar su asistencia.',
  ]);

  /// true si [e] es la respuesta 403 CONSENTIMIENTO_REQUERIDO del servidor.
  static bool esRespuesta(DioException e) {
    if (e.response?.statusCode != 403) return false;
    final data = e.response?.data;
    return data is Map && data['codigo'] == codigo;
  }

  /// Construye la excepción con el mensaje del servidor si viene.
  static ConsentimientoRequeridoException desde(DioException e) {
    final data = e.response?.data;
    final m = data is Map ? data['mensaje'] : null;
    return m is String && m.isNotEmpty
        ? ConsentimientoRequeridoException(m)
        : const ConsentimientoRequeridoException();
  }

  @override
  String toString() => mensaje;
}
