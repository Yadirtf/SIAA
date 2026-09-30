// horario_remote_datasource.dart - Consulta de sesiones del usuario por día (US-ACA-01..09)
// GET /sesiones?fecha=YYYY-MM-DD[&docenteId=] (horario:leer). El backend limita el
// resultado al ámbito del rol activo (el docente solo recibe sus propias sesiones).
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/sesion_horario_model.dart';

class HorarioRemoteDataSource {
  final Dio _dio;

  HorarioRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// Sesiones de un día. Propaga cualquier error: la pantalla lo muestra con reintento.
  Future<List<SesionHorarioModel>> obtenerSesionesDelDia({
    required DateTime fecha,
    String? docenteId,
  }) async {
    final query = <String, dynamic>{'fecha': formatoFecha(fecha)};
    if (docenteId != null && docenteId.isNotEmpty) {
      query['docenteId'] = docenteId;
    }
    final response = await _dio.get('/sesiones', queryParameters: query);
    final data = response.data;
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(SesionHorarioModel.fromJson)
        .toList();
  }

  static String formatoFecha(DateTime f) =>
      '${f.year.toString().padLeft(4, '0')}-${f.month.toString().padLeft(2, '0')}-${f.day.toString().padLeft(2, '0')}';
}
