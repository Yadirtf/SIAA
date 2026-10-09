// derechos_remote_datasource.dart — Cliente HTTP de los derechos del titular (US-LEG-02)
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/canal_derechos.dart';
import '../domain/models/solicitud_derecho.dart';

class DerechosRemoteDataSource {
  final Dio _dio;

  DerechosRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// GET /privacidad/derechos — canal y plazos legales (público).
  Future<CanalDerechos> canal() async {
    final res = await _dio.get('/privacidad/derechos');
    return CanalDerechos.fromJson(res.data as Map<String, dynamic>);
  }

  /// GET /me/datos — copia estructurada de los datos personales (archivo JSON).
  Future<Uint8List> descargarMisDatos() async {
    final res = await _dio.get<List<int>>(
      '/me/datos',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? utf8.encode('{}'));
  }

  /// GET /me/derechos/solicitudes — casos del titular.
  Future<List<SolicitudDerecho>> misSolicitudes() async {
    final res = await _dio.get('/me/derechos/solicitudes');
    final data = res.data;
    return data is List
        ? data
            .whereType<Map<String, dynamic>>()
            .map(SolicitudDerecho.fromJson)
            .toList()
        : const [];
  }

  /// GET /me/derechos/supresion — qué se elimina y qué se conserva.
  Future<List<ElementoSupresion>> evaluarSupresion() async {
    final res = await _dio.get('/me/derechos/supresion');
    final data = res.data;
    return ElementoSupresion.listaDe(data is Map ? data['elementos'] : null);
  }

  /// POST /me/derechos/solicitudes — radica rectificación o supresión.
  Future<SolicitudDerecho> radicar({
    required String tipo,
    required String descripcion,
    Map<String, String> cambios = const {},
  }) async {
    final res = await _dio.post('/me/derechos/solicitudes', data: {
      'tipo': tipo,
      'descripcion': descripcion,
      if (cambios.isNotEmpty) 'cambios': cambios,
    });
    return SolicitudDerecho.fromJson(res.data as Map<String, dynamic>);
  }
}
