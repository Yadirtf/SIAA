// notificaciones_remote_datasource.dart — Cliente HTTP de notificaciones (EP-10)
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/notificacion_model.dart';
import '../domain/models/preferencias_notificacion.dart';

class NotificacionesRemoteDataSource {
  final Dio _dio;

  NotificacionesRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// POST /me/notificaciones/tokens — idempotente.
  Future<void> registrarToken({
    required String token,
    required String plataforma,
    required String dispositivoId,
  }) async {
    await _dio.post('/me/notificaciones/tokens', data: {
      'token': token,
      'plataforma': plataforma,
      'dispositivoId': dispositivoId,
    });
  }

  /// DELETE /me/notificaciones/tokens — al cerrar sesión.
  Future<void> eliminarToken(String token) async {
    await _dio.delete('/me/notificaciones/tokens', data: {'token': token});
  }

  Future<PreferenciasNotificacion> obtenerPreferencias() async {
    final res = await _dio.get('/me/notificaciones/preferencias');
    return PreferenciasNotificacion.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PreferenciasNotificacion> guardarPreferencias(
      PreferenciasNotificacion p) async {
    final res =
        await _dio.put('/me/notificaciones/preferencias', data: p.toJson());
    final data = res.data;
    if (data is! Map<String, dynamic>) return p;
    // El servidor puede omitir "obligatorias" en la respuesta: se conservan.
    return PreferenciasNotificacion.fromJson({
      'obligatorias': p.obligatorias.toList(),
      ...data,
    });
  }

  /// GET /me/notificaciones?limite=N — bandeja en la app.
  Future<List<NotificacionModel>> listar({int limite = 30}) async {
    final res = await _dio
        .get('/me/notificaciones', queryParameters: {'limite': limite});
    final data = res.data;
    final lista = data is List
        ? data
        : (data is Map ? data['items'] as List<dynamic>? : null) ?? const [];
    return lista
        .whereType<Map>()
        .map((e) => NotificacionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST /me/notificaciones/{id}/leida
  Future<void> marcarLeida(String id) async {
    await _dio.post('/me/notificaciones/$id/leida');
  }
}
