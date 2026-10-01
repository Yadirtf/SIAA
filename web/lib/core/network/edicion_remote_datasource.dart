import 'api_client.dart';

/// Guarda la edición de un registro existente (PUT o PATCH sobre su URL).
/// Los errores llegan como `ApiException` con el cuerpo del servidor, para que
/// el formulario los explique sin cerrarse.
class EdicionRemoteDataSource {
  final ApiClient _client;

  EdicionRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> actualizar(
    String url,
    Map<String, dynamic> cuerpo, {
    bool parcial = false,
  }) async {
    final res = parcial
        ? await _client.patch(url, body: cuerpo)
        : await _client.put(url, body: cuerpo);
    return res is Map<String, dynamic> ? res : const {};
  }
}
