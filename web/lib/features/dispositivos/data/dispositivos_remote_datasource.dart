import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/dispositivo_model.dart';

class DispositivosRemoteDataSource {
  final ApiClient _client;

  DispositivosRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  /// Consulta la lista de dispositivos de un usuario (GET /usuarios/:id/dispositivos).
  Future<List<DispositivoModel>> getDispositivosUsuario(
    String usuarioId,
  ) async {
    final url = ApiConstants.dispositivosUsuario(usuarioId);
    final response = await _client.get(url);
    if (response is List) {
      return response
          .map(
            (item) => DispositivoModel.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }
    return [];
  }

  /// Aprueba un dispositivo en estado pendiente (POST /dispositivos/:id/aprobar).
  Future<void> aprobarDispositivo(String dispositivoId) async {
    final url = ApiConstants.aprobarDispositivo(dispositivoId);
    await _client.post(url);
  }

  /// Revoca el acceso de un dispositivo (POST /dispositivos/:id/revocar).
  Future<void> revocarDispositivo(
    String dispositivoId, {
    String? motivo,
  }) async {
    final url = ApiConstants.revocarDispositivo(dispositivoId);
    await _client.post(
      url,
      body: motivo != null && motivo.isNotEmpty ? {'motivo': motivo} : null,
    );
  }
}
