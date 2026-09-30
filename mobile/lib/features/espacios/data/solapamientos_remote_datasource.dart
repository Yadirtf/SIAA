// solapamientos_remote_datasource.dart — GET /espacios/solapamientos (aula:leer)
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../domain/solapamiento_model.dart';

class SolapamientosRemoteDataSource {
  final Dio _dio;

  SolapamientosRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  Future<List<SolapamientoModel>> informe({String? sedeId}) async {
    final res = await _dio.get('/espacios/solapamientos', queryParameters: {
      if (sedeId != null && sedeId.isNotEmpty) 'sedeId': sedeId,
    });
    return SolapamientoModel.listaDesde(res.data);
  }
}
