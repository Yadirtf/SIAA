import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/cambio_sesion.dart';
import 'models/sesion_model.dart';

/// Consulta y cambios puntuales de sesiones de clase (US-ACA-05, US-ACA-06,
/// US-ACA-09): listado, detalle, cancelar, reasignar aula, suplente y
/// reprogramar.
class SesionesRemoteDataSource {
  final ApiClient _client;

  SesionesRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  String _url(String sesionId, [String accion = '']) =>
      '${ApiConstants.sesiones}/$sesionId${accion.isEmpty ? '' : '/$accion'}';

  SesionModel _sesion(dynamic response) =>
      SesionModel.fromJson(response as Map<String, dynamic>);

  Future<List<SesionModel>> getSesiones({
    String? periodoId,
    String? docenteId,
    String? espacioId,
    String? fecha,
    String? estado,
    String? desde,
    String? hasta,
  }) async {
    final params = <String, String>{
      for (final e in {
        'periodoId': periodoId,
        'docenteId': docenteId,
        'espacioId': espacioId,
        'fecha': fecha,
        'estado': estado,
        'desde': desde,
        'hasta': hasta,
      }.entries)
        if (e.value != null && e.value!.isNotEmpty) e.key: e.value!,
    };
    final uri = Uri.parse(ApiConstants.sesiones)
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final response = await _client.get(uri.toString());
    if (response is List) {
      return response
          .map((item) => SesionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// GET /sesiones/:id: incluye los parámetros congelados y los que difieren
  /// de la cascada vigente.
  Future<SesionModel> getSesion(String sesionId) async =>
      _sesion(await _client.get(_url(sesionId)));

  Future<void> cancelarSesion({
    required String sesionId,
    required String motivo,
  }) async {
    await _client.post(_url(sesionId, 'cancelar'), body: {'motivo': motivo});
  }

  Future<SesionModel> reasignarAulaSesion({
    required String sesionId,
    required String nuevoEspacioId,
    required CambioSesion cambio,
  }) async => _sesion(
    await _client.put(
      _url(sesionId, 'aula'),
      body: {'nuevoEspacioId': nuevoEspacioId, ...cambio.toJson()},
    ),
  );

  Future<SesionModel> asignarDocenteReemplazo({
    required String sesionId,
    required String docenteId,
    required CambioSesion cambio,
  }) async => _sesion(
    await _client.patch(
      _url(sesionId, 'docente-reemplazo'),
      body: {'docenteId': docenteId, ...cambio.toJson()},
    ),
  );

  /// PATCH /sesiones/:id/reprogramar (US-ACA-06 AC-01).
  Future<SesionModel> reprogramarSesion({
    required String sesionId,
    required ReprogramacionSesion nueva,
    required CambioSesion cambio,
  }) async => _sesion(
    await _client.patch(
      _url(sesionId, 'reprogramar'),
      body: {...nueva.toJson(), ...cambio.toJson()},
    ),
  );
}
