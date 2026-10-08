import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/archivo_binario.dart';
import 'models/importacion_model.dart';

/// Carga masiva de estructura y horarios en CSV o XLSX (US-ACA-07). El servidor
/// valida siempre el archivo original: se envía el mismo archivo para validar,
/// diagnosticar y aplicar.
class ImportacionRemoteDataSource {
  final ApiClient _client;

  ImportacionRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  /// Informe por fila sin persistir nada (AC-01, AC-04, AC-05).
  Future<PreviewImportacionModel> preview({
    required List<int> bytes,
    required String filename,
  }) async {
    final response = await _client.postMultipart(
      ApiConstants.academicoImportarPreview,
      fileBytes: bytes,
      filename: filename,
    );
    return PreviewImportacionModel.fromJson(response as Map<String, dynamic>);
  }

  /// Revalida y aplica el archivo; un 422 trae el informe sin aplicar nada (AC-03).
  Future<ResultadoImportacionModel> confirmar({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final response = await _client.postMultipart(
        ApiConstants.academicoImportar,
        fileBytes: bytes,
        filename: filename,
      );
      return ResultadoImportacionModel.fromJson(
        response as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      final detalles = e.details;
      if (e.statusCode == 422 &&
          detalles is Map<String, dynamic> &&
          detalles.containsKey('aplicada')) {
        return ResultadoImportacionModel.fromJson(detalles);
      }
      rethrow;
    }
  }

  /// El mismo archivo con la columna de diagnóstico por fila (AC-02).
  Future<ArchivoBinario> diagnostico({
    required List<int> bytes,
    required String filename,
  }) => _client.postMultipartBytes(
    ApiConstants.academicoImportarDiagnostico,
    fileBytes: bytes,
    filename: filename,
  );

  /// Plantilla publicada en `csv` o `xlsx` (T-ACA-07.1).
  Future<ArchivoBinario> plantilla(String formato) =>
      _client.getBytes(ApiConstants.academicoImportarPlantilla(formato));
}
