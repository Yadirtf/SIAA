// privacidad_remote_datasource.dart — Cliente HTTP de aviso y consentimiento (US-LEG-01)
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/estado_consentimiento.dart';
import '../domain/models/politica_privacidad.dart';

/// El servidor rechazó la decisión porque la versión ya no es la vigente (409).
class VersionPoliticaDesactualizadaException implements Exception {
  const VersionPoliticaDesactualizadaException();
}

class PrivacidadRemoteDataSource {
  final Dio _dio;

  PrivacidadRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// GET /privacidad/politica — aviso vigente (público).
  Future<PoliticaPrivacidad> obtenerPolitica() async {
    final res = await _dio.get('/privacidad/politica');
    return PoliticaPrivacidad.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /me/consentimiento — decisión del usuario autenticado.
  Future<EstadoConsentimiento> obtenerConsentimiento() async {
    final res = await _dio.get('/me/consentimiento');
    return EstadoConsentimiento.fromJson(res.data as Map<String, dynamic>);
  }

  /// POST /me/consentimiento — registra la aceptación o el rechazo explícito.
  Future<EstadoConsentimiento> registrarDecision({
    required String version,
    required bool acepta,
    String? dispositivoId,
  }) async {
    try {
      final res = await _dio.post('/me/consentimiento', data: {
        'version': version,
        'acepta': acepta,
        if (dispositivoId != null && dispositivoId.isNotEmpty)
          'dispositivoId': dispositivoId,
      });
      return EstadoConsentimiento.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw const VersionPoliticaDesactualizadaException();
      }
      rethrow;
    }
  }
}
