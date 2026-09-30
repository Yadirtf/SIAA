// justificacion_exception.dart — Error de negocio devuelto por el backend
/// Error tipado con el cuerpo {codigo, mensaje, correlationId} del backend.
class JustificacionException implements Exception {
  final String mensaje;
  final String codigo;
  final int? status;

  const JustificacionException({
    required this.mensaje,
    this.codigo = 'ERROR_DESCONOCIDO',
    this.status,
  });

  @override
  String toString() => mensaje;
}
