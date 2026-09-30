// marcajes_admin_remote_datasource.dart — Fuente remota para administración de marcajes (US-MAR-09)
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/marcaje_admin_model.dart';
import '../../domain/models/sesion_summary_model.dart';
import '../../domain/models/usuario_summary_model.dart';

class MarcajesAdminRemoteDataSource {
  final ApiClient _apiClient;

  MarcajesAdminRemoteDataSource({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  Future<MarcajeAdminPageModel> listarMarcajes({
    FiltrosMarcajeAdmin filtros = const FiltrosMarcajeAdmin(),
    int pagina = 1,
    int limite = 20,
  }) async {
    final queryParams = filtros.toQueryParams(pagina: pagina, limite: limite);
    final uri = Uri.parse(ApiConstants.marcajes).replace(
      queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
    );

    final response = await _apiClient.get(uri.toString());
    if (response is Map<String, dynamic>) {
      return MarcajeAdminPageModel.fromJson(response);
    }
    return const MarcajeAdminPageModel(items: [], total: 0, pagina: 1, limite: 20);
  }

  Future<MarcajeAdminModel> ajustarMarcaje({
    required String marcajeId,
    required String accion,
    String? nuevoResultado,
    required bool anulado,
    required String motivo,
  }) async {
    final url = ApiConstants.ajustarMarcaje(marcajeId);
    final body = {
      'accion': accion,
      if (nuevoResultado != null) 'nuevoResultado': nuevoResultado,
      'anulado': anulado,
      'motivo': motivo,
    };

    final response = await _apiClient.patch(url, body: body);
    return MarcajeAdminModel.fromJson(response as Map<String, dynamic>);
  }

  Future<MarcajeAdminModel> crearMarcajeManual({
    required String sesionId,
    required String usuarioId,
    required String tipo,
    required String resultado,
    required String motivo,
  }) async {
    final body = {
      'sesionId': sesionId,
      'usuarioId': usuarioId,
      'tipo': tipo,
      'resultado': resultado,
      'motivo': motivo,
    };

    final response = await _apiClient.post(ApiConstants.marcajeManual, body: body);
    return MarcajeAdminModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<UsuarioSummaryModel>> obtenerUsuarios() async {
    try {
      final response = await _apiClient.get(ApiConstants.usuarios);
      if (response is List) {
        return response
            .map((item) => UsuarioSummaryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<List<SesionSummaryModel>> obtenerSesiones() async {
    try {
      final response = await _apiClient.get(ApiConstants.sesiones);
      if (response is List) {
        return response
            .map((item) => SesionSummaryModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return const [];
  }
}
