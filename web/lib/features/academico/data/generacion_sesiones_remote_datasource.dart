import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/informe_generacion_model.dart';

/// Materializa las sesiones de un periodo a partir de sus asignaciones
/// (POST /periodos/:id/generar-sesiones, US-ACA-05). Es idempotente: las
/// sesiones que ya existen se omiten.
class GeneracionSesionesRemoteDataSource {
  final ApiClient _client;

  GeneracionSesionesRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  Future<InformeGeneracionModel> generar(String periodoId) async {
    final response = await _client.post(
      ApiConstants.generarSesiones(periodoId),
      body: const <String, dynamic>{},
    );
    return InformeGeneracionModel.fromJson(response as Map<String, dynamic>);
  }
}
