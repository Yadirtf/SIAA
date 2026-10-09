import 'api_exception.dart';

/// Código con el que el backend pide repetir una operación confirmándola
/// (409 CONFIRMACION_REQUERIDA): periodo que se cruza con otro activo, cambio
/// sobre una sesión que ya empezó, etc.
const codigoConfirmacionRequerida = 'CONFIRMACION_REQUERIDA';

/// True si [e] es la respuesta del backend que pide confirmar la operación.
bool requiereConfirmacion(Object e) {
  if (e is! ApiException || e.statusCode != 409) return false;
  final d = e.details;
  return d is Map && d['codigo'] == codigoConfirmacionRequerida;
}

/// El usuario decidió no confirmar: la operación no se aplicó y no hay error
/// que mostrar (el formulario sigue abierto).
class OperacionCancelada implements Exception {
  const OperacionCancelada();

  @override
  String toString() => 'Operación cancelada por el usuario';
}
