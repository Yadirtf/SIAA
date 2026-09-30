import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'models/politica_privacidad_model.dart';

/// Acceso HTTP al aviso de privacidad público (sin token).
class PrivacidadRemoteDataSource {
  final ApiClient _client;

  PrivacidadRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  /// GET /privacidad/politica: versión vigente del aviso.
  Future<PoliticaPrivacidadModel> obtenerPolitica() async {
    final body = await _client.get(
      ApiConstants.politicaPrivacidad,
      requiresAuth: false,
    );
    if (body is! Map) {
      throw ApiException(
        message: 'Respuesta inválida del aviso de privacidad',
        statusCode: 200,
        details: body,
      );
    }
    return PoliticaPrivacidadModel.fromJson(Map<String, dynamic>.from(body));
  }
}
