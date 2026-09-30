import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/archivo_binario.dart';
import '../../academico/data/models/academico_models.dart';
import 'models/filtro_reporte_model.dart';
import 'models/reporte_cumplimiento_model.dart';

/// Acceso HTTP a los reportes de cumplimiento (/api/v1/reportes).
class ReportesRemoteDataSource {
  final ApiClient _client;

  ReportesRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  Future<ReporteCumplimientoModel> cumplimiento(FiltroReporteModel f) async {
    final uri = Uri.parse(ApiConstants.reporteCumplimiento)
        .replace(queryParameters: f.toQuery());
    final resp = await _client.get(uri.toString());
    return ReporteCumplimientoModel.fromJson(
      resp is Map ? Map<String, dynamic>.from(resp) : <String, dynamic>{},
    );
  }

  /// GET /reportes/cumplimiento/exportar?formato=xlsx|pdf&... (binario).
  Future<ArchivoBinario> exportar(FiltroReporteModel f, String formato) {
    final uri = Uri.parse(ApiConstants.exportarCumplimiento)
        .replace(queryParameters: {'formato': formato, ...f.toQuery()});
    return _client.getBytes(uri.toString());
  }

  /// GET /programas?facultadId= (todos si [facultadId] es null).
  Future<List<ProgramaModel>> programas({String? facultadId}) async {
    final uri = Uri.parse(ApiConstants.programas).replace(
      queryParameters: facultadId == null || facultadId.isEmpty
          ? null
          : {'facultadId': facultadId},
    );
    final resp = await _client.get(uri.toString());
    if (resp is! List) return [];
    return resp
        .whereType<Map>()
        .map((e) => ProgramaModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
