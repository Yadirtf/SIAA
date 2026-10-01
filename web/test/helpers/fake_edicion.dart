import 'package:siaa_web/core/network/edicion_remote_datasource.dart';

/// Registra las ediciones enviadas; con [rechazo] simula que el servidor las rechaza.
class FakeEdicion extends EdicionRemoteDataSource {
  final llamadas = <(String, Map<String, dynamic>, bool)>[];
  Object? rechazo;
  Map<String, dynamic> respuesta = const {};

  @override
  Future<Map<String, dynamic>> actualizar(
    String url,
    Map<String, dynamic> cuerpo, {
    bool parcial = false,
  }) async {
    llamadas.add((url, cuerpo, parcial));
    if (rechazo != null) throw rechazo!;
    return respuesta;
  }
}
