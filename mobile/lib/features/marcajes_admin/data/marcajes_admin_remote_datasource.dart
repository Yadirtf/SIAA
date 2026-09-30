// marcajes_admin_remote_datasource.dart — GET /marcajes y PATCH /marcajes/:id (US-MAR-09)
// GET exige marcaje:leer y el backend restringe al ámbito del rol; PATCH exige marcaje:ajustar.
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../marcaje/domain/models/marcaje_historial_model.dart';
import '../domain/filtro_marcajes.dart';

class MarcajesAdminRemoteDataSource {
  final Dio _dio;

  MarcajesAdminRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  Future<HistorialPaginadoModel> listar(FiltroMarcajes filtro) async {
    final res = await _dio.get('/marcajes', queryParameters: filtro.toQuery());
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      return const HistorialPaginadoModel(
          items: [], total: 0, pagina: 1, limite: 20);
    }
    return HistorialPaginadoModel.fromJson(data);
  }

  Future<void> ajustar(String marcajeId, AjusteMarcaje ajuste) async {
    await _dio.patch('/marcajes/$marcajeId', data: ajuste.toJson());
  }
}
