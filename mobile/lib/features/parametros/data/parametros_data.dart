import 'package:dio/dio.dart';

import '../domain/models/parametro_model.dart';
import '../domain/parametros_repository.dart';

/// Datasource remoto para los parámetros efectivos (GET /parametros/efectivos).
/// US-PAR-03: resolución de la cascada con origen de cada clave.
class ParametrosRemoteDataSource {
  final Dio _dio;

  ParametrosRemoteDataSource({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: 'http://localhost:8080/api/v1'));

  Future<ParametrosSnapshot> getEfectivos({
    String? sedeId,
    String? facultadId,
    String? bloqueId,
    String? espacioId,
    String? asignacionId,
  }) async {
    final params = <String, String>{};
    if (sedeId != null && sedeId.isNotEmpty) params['sede_id'] = sedeId;
    if (facultadId != null && facultadId.isNotEmpty) {
      params['facultad_id'] = facultadId;
    }
    if (bloqueId != null && bloqueId.isNotEmpty) params['bloque_id'] = bloqueId;
    if (espacioId != null && espacioId.isNotEmpty) {
      params['espacio_id'] = espacioId;
    }
    if (asignacionId != null && asignacionId.isNotEmpty) {
      params['asignacion_id'] = asignacionId;
    }

    final response = await _dio.get(
      '/parametros/efectivos',
      queryParameters: params.isEmpty ? null : params,
    );
    return ParametrosSnapshot.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

/// Implementación del repositorio de parámetros para mobile.
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
  Future<ParametrosSnapshot> obtenerGlobales() {
    return _remote.getEfectivos();
  }
}
