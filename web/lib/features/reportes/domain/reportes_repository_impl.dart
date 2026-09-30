import '../../../core/network/archivo_binario.dart';
import '../../academico/data/academico_remote_datasource.dart';
import '../../academico/data/models/academico_models.dart';
import '../data/models/filtro_reporte_model.dart';
import '../data/models/reporte_cumplimiento_model.dart';
import '../data/reportes_remote_datasource.dart';
import 'reportes_repository.dart';

class ReportesRepositoryImpl implements ReportesRepository {
  final ReportesRemoteDataSource _remote;
  final AcademicoRemoteDataSource _academico;

  ReportesRepositoryImpl({
    ReportesRemoteDataSource? remoteDataSource,
    AcademicoRemoteDataSource? academico,
  }) : _remote = remoteDataSource ?? ReportesRemoteDataSource(),
       _academico = academico ?? AcademicoRemoteDataSource();

  @override
  Future<ReporteCumplimientoModel> cumplimiento(FiltroReporteModel filtro) =>
      _remote.cumplimiento(filtro);

  @override
  Future<ArchivoBinario> exportar(FiltroReporteModel filtro, String formato) =>
      _remote.exportar(filtro, formato);

  @override
  Future<List<PeriodoModel>> periodos() => _academico.getPeriodos();

  @override
  Future<List<FacultadModel>> facultades() => _academico.getFacultades();

  @override
  Future<List<ProgramaModel>> programas({String? facultadId}) =>
      _remote.programas(facultadId: facultadId);
}
