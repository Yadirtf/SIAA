// marcaje_grupal_remote_datasource.dart — Ventana estudiantil y lista manual del docente
// (US-MAR-13, US-MAR-14). Los errores se propagan como DioException con {codigo, mensaje}.
import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/models/lista_manual_model.dart';
import '../../domain/models/ventana_estudiantil_model.dart';

class MarcajeGrupalRemoteDataSource {
  final Dio _dio;

  MarcajeGrupalRemoteDataSource({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  /// POST /sesiones/{id}/ventana-estudiantil — habilita el marcaje de los estudiantes.
  Future<VentanaEstudiantil> abrirVentana(String sesionId,
      {required int duracionMinutos}) async {
    final res = await _dio.post(
      '/sesiones/$sesionId/ventana-estudiantil',
      data: {'duracionMinutos': duracionMinutos},
    );
    return _ventana(res.data, abierta: true);
  }

  /// DELETE /sesiones/{id}/ventana-estudiantil — cierra la ventana antes de tiempo.
  Future<VentanaEstudiantil> cerrarVentana(String sesionId) async {
    final res = await _dio.delete('/sesiones/$sesionId/ventana-estudiantil');
    return _ventana(res.data, abierta: false);
  }

  /// GET /sesiones/{id}/lista-manual — estudiantes del grupo con su registro actual.
  Future<List<EstudianteListaManual>> consultarLista(String sesionId) async {
    final res = await _dio.get('/sesiones/$sesionId/lista-manual');
    final data = res.data;
    final lista = data is Map<String, dynamic>
        ? data['estudiantes'] as List<dynamic>? ?? const []
        : const [];
    return lista
        .whereType<Map<String, dynamic>>()
        .map(EstudianteListaManual.fromJson)
        .toList();
  }

  /// POST /sesiones/{id}/lista-manual — registra el pase de lista con su motivo.
  Future<ResultadoListaManual> registrarLista({
    required String sesionId,
    required String motivo,
    required Map<String, bool> presentes,
  }) async {
    final res = await _dio.post(
      '/sesiones/$sesionId/lista-manual',
      data: {
        'motivo': motivo,
        'estudiantes': [
          for (final e in presentes.entries)
            {'estudianteId': e.key, 'presente': e.value},
        ],
      },
    );
    final data = res.data;
    return ResultadoListaManual.fromJson(
        data is Map<String, dynamic> ? data : const {});
  }

  VentanaEstudiantil _ventana(Object? data, {required bool abierta}) {
    final json = data is Map<String, dynamic> ? data : <String, dynamic>{};
    return VentanaEstudiantil(
      abierta: json['abierta'] as bool? ?? abierta,
      cierraEn: DateTime.tryParse(json['cierraEn'] as String? ?? ''),
    );
  }
}
