/// Respuesta HTTP con cuerpo decodificado y cabeceras, para los endpoints
/// que devuelven metadatos fuera del cuerpo (p. ej. `X-Total-Count`).
class ApiResponse {
  final dynamic body;
  final Map<String, String> headers;

  const ApiResponse({required this.body, required this.headers});

  /// Lee una cabecera sin distinguir mayúsculas (package:http las normaliza).
  String? header(String nombre) => headers[nombre.toLowerCase()];

  /// Lee una cabecera numérica; null si no existe o no es entera.
  int? intHeader(String nombre) {
    final valor = header(nombre);
    return valor == null ? null : int.tryParse(valor.trim());
  }
}
