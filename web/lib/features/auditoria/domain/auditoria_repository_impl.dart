import '../../../core/models/pagina.dart';
import '../../../core/network/archivo_binario.dart';
import '../data/auditoria_remote_datasource.dart';
import '../data/models/entrada_auditoria_model.dart';
import '../data/models/filtro_auditoria_model.dart';
import 'auditoria_repository.dart';

class AuditoriaRepositoryImpl implements AuditoriaRepository {
  final AuditoriaRemoteDataSource _remote;

  AuditoriaRepositoryImpl({AuditoriaRemoteDataSource? remoteDataSource})
    : _remote = remoteDataSource ?? AuditoriaRemoteDataSource();

  @override
  Future<Pagina<EntradaAuditoriaModel>> consultar(
    FiltroAuditoriaModel filtro,
  ) => _remote.consultar(filtro);

  @override
  Future<ArchivoBinario> exportar(
    FiltroAuditoriaModel filtro,
    String formato,
  ) => _remote.exportar(filtro, formato);
}
