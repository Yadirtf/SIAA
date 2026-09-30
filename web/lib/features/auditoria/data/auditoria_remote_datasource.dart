import '../../../core/constants/api_constants.dart';
import '../../../core/models/pagina.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/archivo_binario.dart';
import 'models/entrada_auditoria_model.dart';
import 'models/filtro_auditoria_model.dart';

/// Acceso HTTP de solo lectura a la bitácora (/api/v1/auditoria).
class AuditoriaRemoteDataSource {
  final ApiClient _client;

  AuditoriaRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  /// GET /auditoria con filtros (total en X-Total-Count).
  Future<Pagina<EntradaAuditoriaModel>> consultar(
    FiltroAuditoriaModel f,
  ) async {
    final uri = Uri.parse(ApiConstants.auditoria)
        .replace(queryParameters: f.toQuery());
    final respuesta = await _client.getWithHeaders(uri.toString());
    final items = respuesta.body is List
        ? (respuesta.body as List)
              .whereType<Map>()
              .map((e) => EntradaAuditoriaModel.fromJson(Map.from(e)))
              .toList()
        : <EntradaAuditoriaModel>[];
    return Pagina(
      items: items,
      total: respuesta.intHeader('X-Total-Count'),
      pagina: f.pagina,
      limite: f.limite,
    );
  }

  /// GET /auditoria/exportar?formato=xlsx|pdf&... (binario).
  Future<ArchivoBinario> exportar(FiltroAuditoriaModel f, String formato) {
    final uri = Uri.parse(ApiConstants.exportarAuditoria).replace(
      queryParameters: {'formato': formato, ...f.toQuery(paginado: false)},
    );
    return _client.getBytes(uri.toString());
  }
}
