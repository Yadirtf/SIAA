// marcaje_remote_datasource.dart — Cliente HTTP para endpoints de marcaje
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/marcaje_historial_model.dart';
import '../../domain/models/marcaje_request_model.dart';
import '../../domain/models/marcaje_result_model.dart';
import '../../domain/models/sesion_activa_model.dart';

class MarcajeRemoteDataSource {
  final Dio _dio;

  MarcajeRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// Obtiene la sesión activa y ventana para el usuario autenticado (§9.5)
  Future<SesionActivaModel?> obtenerSesionActiva() async {
    try {
      final response = await _dio.get('/me/sesiones/activa');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        if (data['sesion'] == null) {
          return null;
        }
        return SesionActivaModel.fromDetalleJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Envía un intento de marcaje para evaluación pura en servidor (§9.4)
  Future<MarcajeResultModel> enviarMarcaje(MarcajeRequestModel request) async {
    final headers = <String, dynamic>{};
    if (request.idempotencyKey != null) {
      headers['Idempotency-Key'] = request.idempotencyKey;
    }

    try {
      final response = await _dio.post(
        '/marcajes',
        data: request.toJson(),
        options: Options(headers: headers),
      );

      final data = response.data as Map<String, dynamic>;
      return MarcajeResultModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null && e.response!.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          return MarcajeResultModel.fromJson(data);
        }
      }
      rethrow;
    }
  }

  /// Sincroniza un lote de marcajes offline (US-MAR-11)
  Future<List<MarcajeResultModel>> sincronizarLote(List<MarcajeRequestModel> lote) async {
    final body = {
      'items': lote.map((e) => e.toJson()).toList(),
    };

    final response = await _dio.post('/marcajes/sync', data: body);
    if (response.statusCode == 200 || response.statusCode == 207) {
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items.map((e) => MarcajeResultModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Consulta el historial cronológico paginado con filtro de mes (US-MAR-08)
  Future<HistorialPaginadoModel> consultarHistorial({
    String? mes,
    int pagina = 1,
    int limite = 20,
  }) async {
    final query = <String, dynamic>{
      'pagina': pagina,
      'limite': limite,
    };
    if (mes != null && mes.isNotEmpty) {
      query['mes'] = mes;
    }

    final response = await _dio.get('/me/historial', queryParameters: query);
    final data = response.data as Map<String, dynamic>;
    return HistorialPaginadoModel.fromJson(data);
  }

  /// Abre la ventana para marcaje de estudiantes del grupo (US-MAR-13)
  Future<DateTime> abrirVentanaEstudiantil(String sesionId, {int duracionMinutos = 5}) async {
    final response = await _dio.post(
      '/sesiones/$sesionId/ventana-estudiantil',
      data: {'duracionMinutos': duracionMinutos},
    );
    final data = response.data as Map<String, dynamic>;
    final cierraEnStr = data['cierraEn'] as String? ?? '';
    return DateTime.tryParse(cierraEnStr) ?? DateTime.now().add(Duration(minutes: duracionMinutos));
  }

  /// Registra el pase de lista manual docente (US-MAR-14)
  Future<void> registrarListaManual({
    required String sesionId,
    required String motivo,
    required List<Map<String, dynamic>> estudiantes,
  }) async {
    await _dio.post(
      '/sesiones/$sesionId/lista-manual',
      data: {
        'motivo': motivo,
        'estudiantes': estudiantes,
      },
    );
  }
}
