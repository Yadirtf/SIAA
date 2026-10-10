import '../../../core/network/archivo_binario.dart';
import '../../academico/data/academico_remote_datasource.dart';
import '../../academico/data/models/academico_models.dart';
import '../data/models/asistencia_grupo_model.dart';
import '../data/models/ocupacion_model.dart';
import '../data/models/tablero_model.dart';
import '../data/reportes_operativos_remote_datasource.dart';

/// Contrato de los reportes operativos de EP-08: tablero en vivo, ocupación
/// de espacios y asistencia estudiantil.
abstract class ReportesOperativosRepository {
  Future<TableroModel> tablero();

  Future<ReporteOcupacionModel> ocupacion(FiltroOcupacionModel filtro);

  Future<ArchivoBinario> exportarOcupacion(
    FiltroOcupacionModel filtro,
    String formato,
  );

  Future<List<PeriodoModel>> periodos();

  Future<List<GrupoReporteModel>> grupos(String periodoId);

  Future<ReporteAsistenciaGrupoModel> asistenciaGrupo(String grupoId);
}

class ReportesOperativosRepositoryImpl implements ReportesOperativosRepository {
  final ReportesOperativosRemoteDataSource _remote;
  final AcademicoRemoteDataSource _academico;

  ReportesOperativosRepositoryImpl({
    ReportesOperativosRemoteDataSource? remote,
    AcademicoRemoteDataSource? academico,
  }) : _remote = remote ?? ReportesOperativosRemoteDataSource(),
       _academico = academico ?? AcademicoRemoteDataSource();

  @override
  Future<TableroModel> tablero() => _remote.tablero();

  @override
  Future<ReporteOcupacionModel> ocupacion(FiltroOcupacionModel filtro) =>
      _remote.ocupacion(filtro);

  @override
  Future<ArchivoBinario> exportarOcupacion(
    FiltroOcupacionModel filtro,
    String formato,
  ) => _remote.exportarOcupacion(filtro, formato);

  @override
  Future<List<PeriodoModel>> periodos() => _academico.getPeriodos();

  @override
  Future<List<GrupoReporteModel>> grupos(String periodoId) =>
      _remote.grupos(periodoId);

  @override
  Future<ReporteAsistenciaGrupoModel> asistenciaGrupo(String grupoId) =>
      _remote.asistenciaGrupo(grupoId);
}
