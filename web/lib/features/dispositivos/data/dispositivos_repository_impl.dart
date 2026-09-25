import '../domain/dispositivos_repository.dart';
import '../domain/models/dispositivo_model.dart';
import 'dispositivos_remote_datasource.dart';

class DispositivosRepositoryImpl implements DispositivosRepository {
  final DispositivosRemoteDataSource _remoteDataSource;

  DispositivosRepositoryImpl({DispositivosRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? DispositivosRemoteDataSource();

  @override
  Future<List<DispositivoModel>> obtenerDispositivosUsuario(String usuarioId) {
    return _remoteDataSource.getDispositivosUsuario(usuarioId);
  }

  @override
  Future<void> aprobarDispositivo(String dispositivoId) {
    return _remoteDataSource.aprobarDispositivo(dispositivoId);
  }

  @override
  Future<void> revocarDispositivo(String dispositivoId, {String? motivo}) {
    return _remoteDataSource.revocarDispositivo(dispositivoId, motivo: motivo);
  }
}
