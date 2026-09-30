// reportes_remote_datasource.dart — GET /reportes/cumplimiento (reporte:leer) y GET /periodos
// (horario:leer). El backend exige periodoId o el rango desde/hasta (AAAA-MM-DD).
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/fechas_es.dart';
import '../domain/reporte_cumplimiento.dart';

class ReportesRemoteDataSource {
  final Dio _dio;

  ReportesRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  Future<ReporteCumplimiento> cumplimiento({
    String? periodoId,
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final query = <String, dynamic>{
      if (periodoId != null && periodoId.isNotEmpty) 'periodoId': periodoId,
      if ((periodoId == null || periodoId.isEmpty) && desde != null)
        'desde': fechaIso(desde),
      if ((periodoId == null || periodoId.isEmpty) && hasta != null)
        'hasta': fechaIso(hasta),
    };
    final res =
        await _dio.get('/reportes/cumplimiento', queryParameters: query);
    return ReporteCumplimiento.fromJson(res.data as Map<String, dynamic>);
  }

  /// Periodos disponibles; lista vacía si el rol no puede consultarlos.
  Future<List<PeriodoOpcion>> periodos() async {
    try {
      final res = await _dio.get('/periodos');
      final data = res.data is List ? res.data as List : const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(PeriodoOpcion.fromJson)
          .where((p) => p.id.isNotEmpty)
          .toList();
    } on DioException {
      return const [];
    }
  }
}
