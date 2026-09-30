import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/geo_models.dart';

/// Guarda el polígono de un aula dibujado en el mapa de escritorio
/// (PUT /espacios/:id/geometria, RF-GEO-002). El backend cierra el anillo,
/// valida la topología y detecta solapamientos con aulas del mismo piso.
class GeometriaRemoteDataSource {
  final ApiClient _client;

  GeometriaRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  Future<EspacioModel> guardar({
    required String espacioId,
    required List<List<double>> vertices,
    bool confirmarSolapamiento = false,
    String? motivoSolapamiento,
  }) async {
    final body = <String, dynamic>{
      'coordenadas': vertices,
      'metodoCaptura': 'TOQUE_MAPA',
      'confirmarSolapamiento': confirmarSolapamiento,
    };
    if (motivoSolapamiento != null && motivoSolapamiento.isNotEmpty) {
      body['motivoSolapamiento'] = motivoSolapamiento;
    }
    final response = await _client.put(
      '${ApiConstants.espacios}/$espacioId/geometria',
      body: body,
    );
    return EspacioModel.fromJson(response as Map<String, dynamic>);
  }
}
