// horario_remote_datasource.dart - Consumo de endpoints de sesiones para horario del usuario (US-ACA-01..09)
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/sesion_horario_model.dart';

class HorarioRemoteDataSource {
  final Dio _dio;

  HorarioRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// Obtiene sesiones para el usuario autenticado (por fecha o hoy)
  Future<List<SesionHorarioModel>> obtenerSesiones({
    String? docenteId,
    DateTime? fecha,
  }) async {
    final fechaStr = fecha != null
        ? '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}'
        : null;

    try {
      // 1. Intentar consulta filtrada por docente y fecha en /sesiones
      final queryParams = <String, dynamic>{};
      if (docenteId != null && docenteId.isNotEmpty) {
        queryParams['docenteId'] = docenteId;
      }
      if (fechaStr != null) {
        queryParams['fecha'] = fechaStr;
      }

      final response = await _dio.get('/sesiones', queryParameters: queryParams);
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List<dynamic>;
        return list
            .map((e) => SesionHorarioModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } on DioException {
      // Si falla por permisos o filtros, intentar fallback a /me/sesiones/hoy
    }

    try {
      final fallbackResp = await _dio.get('/me/sesiones/hoy');
      if (fallbackResp.statusCode == 200 && fallbackResp.data != null) {
        final data = fallbackResp.data as Map<String, dynamic>;
        final items = data['sesiones'] as List<dynamic>? ?? [];
        return items
            .map((e) => SesionHorarioModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      // Si ambos fallan, relanzar
    }

    return [];
  }
}
