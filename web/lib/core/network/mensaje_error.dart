import 'api_exception.dart';

/// Texto legible de un error: el `mensaje` del backend si existe.
String mensajeDeError(Object e) {
  if (e is ApiException) return e.message;
  return e.toString().replaceAll('Exception: ', '');
}
