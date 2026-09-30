// justificacion_remote_datasource.dart — Cliente HTTP de /justificaciones (EP-07)
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/models/justificacion_exception.dart';
import '../../domain/models/justificacion_model.dart';
import '../../domain/models/soporte_adjunto.dart';

class JustificacionRemoteDataSource {
  final Dio _dio;

  JustificacionRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// POST /justificaciones como multipart/form-data (RF-JUS-001).
  Future<Justificacion> radicar({
    required String sesionId,
    required String tipo,
    required String descripcion,
    required List<SoporteAdjunto> soportes,
  }) {
    final form = FormData.fromMap({
      'sesionId': sesionId,
      'tipo': tipo,
      'descripcion': descripcion,
    });
    for (final s in soportes) {
      form.files.add(MapEntry(
        'soportes',
        MultipartFile.fromBytes(
          s.bytes,
          filename: s.nombre,
          contentType: DioMediaType.parse(s.mime),
        ),
      ));
    }
    return _ejecutar(() async {
      final res = await _dio.post('/justificaciones', data: form);
      return Justificacion.fromJson(res.data as Map<String, dynamic>);
    });
  }

  /// GET /justificaciones — justificaciones propias del docente.
  Future<PaginaJustificaciones> listar({
    String? estado,
    int pagina = 1,
    int limite = 20,
  }) {
    final query = <String, dynamic>{'pagina': pagina, 'limite': limite};
    if (estado != null && estado.isNotEmpty) query['estado'] = estado;
    return _ejecutar(() async {
      final res = await _dio.get('/justificaciones', queryParameters: query);
      final raw = res.data as List<dynamic>? ?? const [];
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(Justificacion.fromJson)
          .toList();
      final total = int.tryParse(res.headers.value('x-total-count') ?? '');
      return PaginaJustificaciones(items: items, total: total ?? items.length);
    });
  }

  /// GET /justificaciones/{id} — detalle con historial y observaciones.
  Future<Justificacion> obtener(String id) {
    return _ejecutar(() async {
      final res = await _dio.get('/justificaciones/$id');
      return Justificacion.fromJson(res.data as Map<String, dynamic>);
    });
  }

  Future<T> _ejecutar<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on DioException catch (e) {
      throw mapearErrorJustificacion(e);
    }
  }
}

/// Traduce un error de Dio al mensaje del backend o a uno de red legible.
JustificacionException mapearErrorJustificacion(DioException e) {
  final data = e.response?.data;
  final status = e.response?.statusCode;
  if (data is Map<String, dynamic> && data['mensaje'] is String) {
    return JustificacionException(
      mensaje: data['mensaje'] as String,
      codigo: data['codigo'] as String? ?? 'ERROR_DESCONOCIDO',
      status: status,
    );
  }
  return JustificacionException(mensaje: _mensajeRed(e), status: status);
}

String _mensajeRed(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'La conexión tardó demasiado. Verifica tu internet.';
    case DioExceptionType.connectionError:
      return 'No se pudo conectar al servidor. Verifica tu conexión.';
    default:
      return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
  }
}
