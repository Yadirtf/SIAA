// api_error.dart — Traducción de errores HTTP a mensajes legibles (SIAA Móvil)
// El backend responde {codigo, mensaje}; si no hay cuerpo se usa un texto de red.
import 'package:dio/dio.dart';

/// Mensaje legible para mostrar al usuario a partir de cualquier error de red.
String mensajeDeError(Object error,
    {String porDefecto = 'Ocurrió un error inesperado. Inténtalo de nuevo.'}) {
  if (error is! DioException) {
    // Repositorios que envuelven el mensaje del backend en Exception(mensaje).
    final texto = error.toString();
    const prefijo = 'Exception: ';
    return error is Exception &&
            texto.startsWith(prefijo) &&
            texto.length > prefijo.length
        ? texto.substring(prefijo.length)
        : porDefecto;
  }
  final data = error.response?.data;
  if (data is Map) {
    for (final clave in const ['mensaje', 'message']) {
      final texto = data[clave];
      if (texto is String && texto.trim().isNotEmpty) return texto;
    }
  }
  switch (error.response?.statusCode) {
    case 401:
      return 'Tu sesión expiró. Inicia sesión de nuevo.';
    case 403:
      return 'No tienes permiso para consultar esta información.';
    case 404:
      return 'El recurso solicitado no existe en el servidor.';
  }
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'La conexión tardó demasiado. Verifica tu internet.';
    case DioExceptionType.connectionError:
      return 'No se pudo conectar al servidor. Verifica tu conexión.';
    default:
      return porDefecto;
  }
}

/// Código HTTP de un error de Dio (null si no hubo respuesta).
int? estadoHttpDe(Object error) =>
    error is DioException ? error.response?.statusCode : null;
