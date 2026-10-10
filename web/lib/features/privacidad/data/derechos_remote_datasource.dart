import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/solicitud_derecho_model.dart';

/// Bandeja de solicitudes de derechos de los titulares (usuario:editar, US-LEG-02).
class DerechosRemoteDataSource {
  final ApiClient _client;

  DerechosRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  static const _base = '${ApiConstants.baseUrl}/privacidad/solicitudes';

  /// GET /privacidad/solicitudes[?abiertas=true]: lo que vence primero, primero.
  Future<List<SolicitudDerechoModel>> listar({bool soloAbiertas = true}) async {
    final body = await _client.get(
      soloAbiertas ? '$_base?abiertas=true' : _base,
    );
    return body is List
        ? body
              .whereType<Map>()
              .map((e) => SolicitudDerechoModel.fromJson(Map.from(e)))
              .toList()
        : const [];
  }

  /// POST /privacidad/solicitudes/{id}/asumir: queda a cargo de quien atiende.
  Future<void> asumir(String id) => _client.post('$_base/$id/asumir');

  /// POST /privacidad/solicitudes/{id}/resolver {atendida, respuesta}.
  Future<void> resolver(
    String id, {
    required bool atendida,
    required String respuesta,
  }) => _client.post(
    '$_base/$id/resolver',
    body: {'atendida': atendida, 'respuesta': respuesta},
  );
}
