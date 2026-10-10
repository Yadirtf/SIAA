import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/informe_generacion_model.dart';
import 'models/trabajo_model.dart';

/// Materializa las sesiones de un periodo a partir de sus asignaciones
/// (POST /periodos/:id/generar-sesiones, US-ACA-05). Es idempotente: las
/// sesiones que ya existen se omiten.
class GeneracionSesionesRemoteDataSource {
  final ApiClient _client;

  GeneracionSesionesRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  /// Generación síncrona: responde con el informe al terminar.
  Future<InformeGeneracionModel> generar(String periodoId) async {
    final response = await _client.post(
      ApiConstants.generarSesiones(periodoId),
      body: const <String, dynamic>{},
    );
    return InformeGeneracionModel.fromJson(response as Map<String, dynamic>);
  }

  /// Inicia la generación en segundo plano (202) y devuelve el trabajo que se
  /// consulta con [consultarTrabajo] (US-ACA-05 AC-04). Con [incluirPasadas]
  /// también genera las fechas del periodo que ya pasaron.
  Future<TrabajoModel> iniciarGeneracion(
    String periodoId, {
    bool incluirPasadas = false,
  }) async {
    final response = await _client.post(
      ApiConstants.generarSesiones(periodoId),
      body: {'asincrono': true, if (incluirPasadas) 'incluirPasadas': true},
    );
    return TrabajoModel.fromJson(response as Map<String, dynamic>);
  }

  /// GET /trabajos/:id: estado y, al terminar, el informe en `resultado`.
  Future<TrabajoModel> consultarTrabajo(String trabajoId) async {
    final response = await _client.get(ApiConstants.trabajo(trabajoId));
    return TrabajoModel.fromJson(response as Map<String, dynamic>);
  }
}
