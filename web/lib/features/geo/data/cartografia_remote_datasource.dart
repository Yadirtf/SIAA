import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/archivo_binario.dart';
import 'models/preview_cartografia_model.dart';

/// Formatos de intercambio de cartografía (US-GEO-11).
const formatosCartografia = ['geojson', 'kml'];

/// Importación y exportación de cartografía GeoJSON/KML contra el backend
/// (`/espacios/importar/preview`, `/espacios/importar`, `/espacios/exportar`).
class CartografiaRemoteDataSource {
  final ApiClient _client;

  CartografiaRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  /// Sube el archivo; el backend detecta el formato por la extensión o el
  /// contenido y valida cada espacio antes de persistir nada (AC-01, AC-04).
  Future<PreviewCartografiaModel> previsualizar({
    required List<int> bytes,
    required String nombreArchivo,
  }) async {
    final r = await _client.postMultipart(
      '${ApiConstants.espacios}/importar/preview',
      fileBytes: bytes,
      filename: nombreArchivo,
    );
    return PreviewCartografiaModel.fromJson(r as Map<String, dynamic>);
  }

  /// Confirma la importación de los elementos previsualizados (AC-02).
  Future<ResultadoImportacionCartografia> confirmar({
    required String sedeId,
    String? bloqueId,
    int? piso,
    required List<Map<String, dynamic>> elementos,
  }) async {
    final r = await _client.post(
      '${ApiConstants.espacios}/importar',
      body: {
        'sedeId': sedeId,
        if (bloqueId != null && bloqueId.isNotEmpty) 'bloqueId': bloqueId,
        if (piso != null) 'piso': piso,
        'elementos': elementos,
      },
    );
    return ResultadoImportacionCartografia.fromJson(r as Map<String, dynamic>);
  }

  /// Descarga la cartografía de la sede en GeoJSON o KML (AC-03).
  Future<ArchivoBinario> exportar({
    required String sedeId,
    required String formato,
  }) {
    final uri = Uri.parse('${ApiConstants.espacios}/exportar')
        .replace(queryParameters: {'sedeId': sedeId, 'formato': formato});
    return _client.getBytes(uri.toString());
  }
}
