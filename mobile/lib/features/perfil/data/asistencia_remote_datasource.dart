// asistencia_remote_datasource.dart — GET /me/asistencia: asistencia acumulada del
// estudiante por asignatura (US-MAR-13 AC-05).
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/asistencia_asignatura.dart';

class AsistenciaRemoteDataSource {
  final Dio _dio;

  AsistenciaRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  Future<List<AsistenciaAsignatura>> miAsistencia() async {
    final res = await _dio.get('/me/asistencia');
    final data = res.data;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AsistenciaAsignatura.fromJson)
        .toList();
  }
}
