import '../../../core/network/archivo_binario.dart';
import '../data/importacion_remote_datasource.dart';
import '../data/models/importacion_model.dart';

/// Contrato de la carga masiva académica (US-ACA-07).
abstract class ImportacionRepository {
  Future<PreviewImportacionModel> preview(List<int> bytes, String nombre);
  Future<ResultadoImportacionModel> confirmar(List<int> bytes, String nombre);
  Future<ArchivoBinario> diagnostico(List<int> bytes, String nombre);
  Future<ArchivoBinario> plantilla(String formato);
}

class ImportacionRepositoryImpl implements ImportacionRepository {
  final ImportacionRemoteDataSource _remote;

  ImportacionRepositoryImpl({ImportacionRemoteDataSource? remote})
    : _remote = remote ?? ImportacionRemoteDataSource();

  @override
  Future<PreviewImportacionModel> preview(List<int> bytes, String nombre) =>
      _remote.preview(bytes: bytes, filename: nombre);

  @override
  Future<ResultadoImportacionModel> confirmar(List<int> bytes, String nombre) =>
      _remote.confirmar(bytes: bytes, filename: nombre);

  @override
  Future<ArchivoBinario> diagnostico(List<int> bytes, String nombre) =>
      _remote.diagnostico(bytes: bytes, filename: nombre);

  @override
  Future<ArchivoBinario> plantilla(String formato) =>
      _remote.plantilla(formato);
}
