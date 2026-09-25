// horario_repository_impl.dart - Implementación de HorarioRepository (US-ACA-01..09)
import '../../domain/repositories/horario_repository.dart';
import '../datasources/horario_remote_datasource.dart';
import '../models/sesion_horario_model.dart';

class HorarioRepositoryImpl implements HorarioRepository {
  final HorarioRemoteDataSource _remoteDataSource;

  HorarioRepositoryImpl({HorarioRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? HorarioRemoteDataSource();

  @override
  Future<List<SesionHorarioModel>> obtenerHorario({
    String? docenteId,
    DateTime? fecha,
  }) async {
    return _remoteDataSource.obtenerSesiones(
      docenteId: docenteId,
      fecha: fecha,
    );
  }
}
