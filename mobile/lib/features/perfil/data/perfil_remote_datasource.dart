// perfil_remote_datasource.dart — GET /me/perfil (cualquier usuario autenticado)
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/perfil_model.dart';

class PerfilRemoteDataSource {
  final Dio _dio;

  PerfilRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// Perfil del usuario autenticado; null si el servidor aún no expone /me/perfil (404).
  Future<PerfilModel?> obtener() async {
    try {
      final res = await _dio.get('/me/perfil');
      final data = res.data;
      return data is Map<String, dynamic> ? PerfilModel.fromJson(data) : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
