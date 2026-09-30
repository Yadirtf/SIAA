import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/parametro_model.dart';
import '../domain/parametros_repository.dart';

/// Datasource remoto para el módulo de parametrización (web).
/// Consume GET /parametros/efectivos y PUT /parametros.
class ParametrosRemoteDataSource {
  final ApiClient _client;

  ParametrosRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  /// GET /parametros/efectivos con query params de ámbito.
  Future<ParametrosSnapshot> getEfectivos({
    String? sedeId,
    String? facultadId,
    String? bloqueId,
    String? espacioId,
    String? asignacionId,
  }) async {
    final params = <String>[];
    if (sedeId != null && sedeId.isNotEmpty) params.add('sede_id=$sedeId');
    if (facultadId != null && facultadId.isNotEmpty) {
      params.add('facultad_id=$facultadId');
    }
    if (bloqueId != null && bloqueId.isNotEmpty) {
      params.add('bloque_id=$bloqueId');
    }
    if (espacioId != null && espacioId.isNotEmpty) {
      params.add('espacio_id=$espacioId');
    }
    if (asignacionId != null && asignacionId.isNotEmpty) {
      params.add('asignacion_id=$asignacionId');
    }

    final suffix = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = '${ApiConstants.parametrosEfectivos}$suffix';

    final response = await _client.get(url);
    return ParametrosSnapshot.fromJson(response as Map<String, dynamic>);
  }

  /// PUT /parametros — inserta o actualiza un parámetro por ámbito+clave.
  Future<void> putParametro(GuardarParametroRequest request) async {
    await _client.put(ApiConstants.parametros, body: request.toJson());
  }
}

/// Implementación del repositorio de parámetros para la consola web.
class ParametrosRepositoryImpl implements ParametrosRepository {
  final ParametrosRemoteDataSource _remote;

  ParametrosRepositoryImpl({ParametrosRemoteDataSource? remote})
    : _remote = remote ?? ParametrosRemoteDataSource();

  @override
  Future<ParametrosSnapshot> obtenerEfectivos({
    String? sedeId,
    String? facultadId,
    String? bloqueId,
    String? espacioId,
    String? asignacionId,
  }) {
    return _remote.getEfectivos(
      sedeId: sedeId,
      facultadId: facultadId,
      bloqueId: bloqueId,
      espacioId: espacioId,
      asignacionId: asignacionId,
    );
  }

  @override
  Future<void> guardarParametro(GuardarParametroRequest request) {
    return _remote.putParametro(request);
  }
}
