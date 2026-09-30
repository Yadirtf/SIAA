// horario_repository_impl.dart - Implementación de HorarioRepository (US-ACA-01..09)
// Una petición por día de la semana (lunes a sábado), en paralelo.
import '../../domain/repositories/horario_repository.dart';
import '../datasources/horario_remote_datasource.dart';
import '../models/sesion_horario_model.dart';

class HorarioRepositoryImpl implements HorarioRepository {
  static const diasLectivos = 6;

  final HorarioRemoteDataSource _remoteDataSource;

  HorarioRepositoryImpl({HorarioRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? HorarioRemoteDataSource();

  @override
  Future<Map<DateTime, List<SesionHorarioModel>>> obtenerSemana({
    required DateTime lunes,
    String? docenteId,
  }) async {
    final dias = List.generate(
      diasLectivos,
      (i) => DateTime(lunes.year, lunes.month, lunes.day + i),
    );
    final resultados = await Future.wait(dias.map(
      (d) => _remoteDataSource.obtenerSesionesDelDia(
        fecha: d,
        docenteId: docenteId,
      ),
    ));
    return {
      for (var i = 0; i < dias.length; i++)
        dias[i]: [...resultados[i]]
          ..sort((a, b) => a.horaInicio.compareTo(b.horaInicio)),
    };
  }
}
