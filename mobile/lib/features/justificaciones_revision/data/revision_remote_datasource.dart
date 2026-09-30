// revision_remote_datasource.dart — Bandeja de revisión de justificaciones (RF-JUS-002)
// GET /justificaciones (justificacion:leer, acotado al ámbito), PATCH /justificaciones/:id
// (justificacion:aprobar), soportes y nombre del docente (GET /usuarios/:id, usuario:leer).
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../justificaciones/domain/models/justificacion_model.dart';

class RevisionRemoteDataSource {
  static const limite = 20;

  final Dio _dio;

  RevisionRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  Future<PaginaJustificaciones> listar({String? estado, int pagina = 1}) async {
    final res = await _dio.get('/justificaciones', queryParameters: {
      'pagina': pagina,
      'limite': limite,
      if (estado != null) 'estado': estado,
    });
    final raw = res.data is List ? res.data as List : const [];
    final items = raw
        .whereType<Map<String, dynamic>>()
        .map(Justificacion.fromJson)
        .toList();
    final total = int.tryParse(res.headers.value('x-total-count') ?? '');
    return PaginaJustificaciones(items: items, total: total ?? items.length);
  }

  Future<Justificacion> obtener(String id) async {
    final res = await _dio.get('/justificaciones/$id');
    return Justificacion.fromJson(res.data as Map<String, dynamic>);
  }

  /// PATCH {estado: EN_REVISION|APROBADA|RECHAZADA, observaciones}.
  Future<Justificacion> revisar(String id,
      {required String estado, String? observaciones}) async {
    final res = await _dio.patch('/justificaciones/$id', data: {
      'estado': estado,
      if (observaciones != null && observaciones.trim().isNotEmpty)
        'observaciones': observaciones.trim(),
    });
    return Justificacion.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Uint8List> descargarSoporte(String id, String soporteId) async {
    final res = await _dio.get<List<int>>(
      '/justificaciones/$id/soportes/$soporteId',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data ?? const []);
  }

  /// Nombre completo de un usuario; cadena vacía si no se puede resolver.
  Future<String> nombreUsuario(String id) async {
    final res = await _dio.get('/usuarios/$id');
    final data = res.data;
    if (data is! Map) return '';
    return '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'.trim();
  }
}
