import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/archivo_binario.dart';
import 'models/asistencia_grupo_model.dart';
import 'models/lectura_json.dart';
import 'models/ocupacion_model.dart';
import 'models/tablero_model.dart';

/// Acceso HTTP al tablero en vivo, la ocupación de espacios y la asistencia
/// estudiantil (US-REP-03, US-REP-04, US-REP-05).
class ReportesOperativosRemoteDataSource {
  final ApiClient _client;

  ReportesOperativosRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  Future<Map<String, dynamic>> _getMapa(String url) async =>
      jsonMapa(await _client.get(url));

  /// GET /reportes/tablero.
  Future<TableroModel> tablero() async =>
      TableroModel.fromJson(await _getMapa(ApiConstants.reporteTablero));

  /// GET /reportes/ocupacion?agrupacion=&periodoId=&desde=&hasta=.
  Future<ReporteOcupacionModel> ocupacion(FiltroOcupacionModel f) async {
    final uri = Uri.parse(ApiConstants.reporteOcupacion)
        .replace(queryParameters: f.toQuery());
    return ReporteOcupacionModel.fromJson(await _getMapa(uri.toString()));
  }

  /// GET /reportes/ocupacion/exportar?formato=xlsx|pdf&... (binario).
  Future<ArchivoBinario> exportarOcupacion(
    FiltroOcupacionModel f,
    String formato,
  ) {
    final uri = Uri.parse(ApiConstants.exportarOcupacion)
        .replace(queryParameters: {'formato': formato, ...f.toQuery()});
    return _client.getBytes(uri.toString());
  }

  /// GET /reportes/asistencia-estudiantil/grupos?periodoId=.
  Future<List<GrupoReporteModel>> grupos(String periodoId) async {
    final uri = Uri.parse(ApiConstants.gruposAsistenciaEstudiantil)
        .replace(queryParameters: {'periodoId': periodoId});
    final resp = await _client.get(uri.toString());
    return jsonLista(resp).map(GrupoReporteModel.fromJson).toList();
  }

  /// GET /reportes/asistencia-estudiantil?grupoId=.
  Future<ReporteAsistenciaGrupoModel> asistenciaGrupo(String grupoId) async {
    final uri = Uri.parse(ApiConstants.reporteAsistenciaEstudiantil)
        .replace(queryParameters: {'grupoId': grupoId});
    return ReporteAsistenciaGrupoModel.fromJson(await _getMapa(uri.toString()));
  }
}
