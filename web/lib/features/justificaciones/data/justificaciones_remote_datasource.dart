import '../../../core/constants/api_constants.dart';
import '../../../core/models/pagina.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/archivo_binario.dart';
import 'models/justificacion_model.dart';
import 'models/justificaciones_filtro.dart';

/// Acceso HTTP a la revisión de justificaciones (/api/v1/justificaciones).
class JustificacionesRemoteDataSource {
  final ApiClient _client;

  JustificacionesRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  /// GET /justificaciones con filtros (total en X-Total-Count).
  Future<Pagina<JustificacionModel>> listar(JustificacionesFiltro f) async {
    final uri = Uri.parse(ApiConstants.justificaciones)
        .replace(queryParameters: f.toQuery());
    final respuesta = await _client.getWithHeaders(uri.toString());
    final items = respuesta.body is List
        ? (respuesta.body as List)
              .whereType<Map>()
              .map((e) => JustificacionModel.fromJson(Map.from(e)))
              .toList()
        : <JustificacionModel>[];
    return Pagina(
      items: items,
      total: respuesta.intHeader('X-Total-Count'),
      pagina: f.pagina,
      limite: f.limite,
    );
  }

  Future<JustificacionModel> obtener(String id) async =>
      _modelo(await _client.get(ApiConstants.justificacion(id)));

  /// PATCH /justificaciones/{id} → justificación actualizada.
  Future<JustificacionModel> revisar(
    String id, {
    required String estado,
    String? observaciones,
  }) async {
    final resp = await _client.patch(
      ApiConstants.justificacion(id),
      body: {
        'estado': estado,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      },
    );
    return _modelo(resp);
  }

  /// Contenido binario de un soporte (PDF o imagen).
  Future<ArchivoBinario> descargarSoporte(String id, String soporteId) =>
      _client.getBytes(ApiConstants.soporteJustificacion(id, soporteId));

  /// Nombre completo del usuario (GET /usuarios/{id}).
  Future<String> nombreUsuario(String id) async {
    final resp = await _client.get(ApiConstants.usuario(id));
    if (resp is! Map) return '';
    return '${resp['nombre'] ?? ''} ${resp['apellido'] ?? ''}'.trim();
  }

  JustificacionModel _modelo(dynamic resp) => JustificacionModel.fromJson(
    resp is Map ? Map<String, dynamic>.from(resp) : <String, dynamic>{},
  );
}
