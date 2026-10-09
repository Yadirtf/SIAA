import '../data/academico_remote_datasource.dart';
import '../data/models/academico_models.dart';
import '../data/models/sesion_model.dart';
import '../data/sesiones_remote_datasource.dart';
import 'academico_repository.dart';

/// Implementación remota: la estructura académica va a
/// [AcademicoRemoteDataSource] y las sesiones a [SesionesRemoteDataSource].
class AcademicoRepositoryImpl implements AcademicoRepository {
  final AcademicoRemoteDataSource _remoteDataSource;
  final SesionesRemoteDataSource _sesiones;

  AcademicoRepositoryImpl({
    AcademicoRemoteDataSource? remoteDataSource,
    SesionesRemoteDataSource? sesionesDataSource,
  }) : _remoteDataSource = remoteDataSource ?? AcademicoRemoteDataSource(),
       _sesiones = sesionesDataSource ?? SesionesRemoteDataSource();

  @override
  Future<List<PeriodoModel>> getPeriodos() => _remoteDataSource.getPeriodos();

  @override
  Future<PeriodoModel> createPeriodo({
    required String codigo,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required String estado,
    bool confirmarSolapamiento = false,
  }) => _remoteDataSource.createPeriodo(
    codigo: codigo,
    nombre: nombre,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    estado: estado,
    confirmarSolapamiento: confirmarSolapamiento,
  );

  @override
  Future<List<FacultadModel>> getFacultades() =>
      _remoteDataSource.getFacultades();

  @override
  Future<FacultadModel> createFacultad({
    required String codigo,
    required String nombre,
    String? sedeId,
  }) => _remoteDataSource.createFacultad(
    codigo: codigo,
    nombre: nombre,
    sedeId: sedeId,
  );

  @override
  Future<void> deleteFacultad(String id) =>
      _remoteDataSource.deleteFacultad(id);

  @override
  Future<List<ProgramaModel>> getProgramas() =>
      _remoteDataSource.getProgramas();

  @override
  Future<ProgramaModel> createPrograma({
    required String codigo,
    required String nombre,
    required String facultadId,
  }) => _remoteDataSource.createPrograma(
    codigo: codigo,
    nombre: nombre,
    facultadId: facultadId,
  );

  @override
  Future<void> deletePrograma(String id) =>
      _remoteDataSource.deletePrograma(id);

  @override
  Future<List<AsignaturaModel>> getAsignaturas() =>
      _remoteDataSource.getAsignaturas();

  @override
  Future<AsignaturaModel> createAsignatura({
    required String codigo,
    required String nombre,
    required String programaId,
    required int creditos,
  }) => _remoteDataSource.createAsignatura(
    codigo: codigo,
    nombre: nombre,
    programaId: programaId,
    creditos: creditos,
  );

  @override
  Future<void> deleteAsignatura(String id) =>
      _remoteDataSource.deleteAsignatura(id);

  @override
  Future<List<GrupoModel>> getGrupos() => _remoteDataSource.getGrupos();

  @override
  Future<GrupoModel> createGrupo({
    required String numero,
    required String asignaturaId,
    required String periodoId,
    required int cupo,
  }) => _remoteDataSource.createGrupo(
    numero: numero,
    asignaturaId: asignaturaId,
    periodoId: periodoId,
    cupo: cupo,
  );

  @override
  Future<List<AsignacionModel>> getAsignaciones() =>
      _remoteDataSource.getAsignaciones();

  @override
  Future<AsignacionModel> createAsignacion(Map<String, dynamic> body) =>
      _remoteDataSource.createAsignacion(body);

  @override
  Future<void> deleteAsignacion(String id) =>
      _remoteDataSource.deleteAsignacion(id);

  @override
  Future<List<ExcepcionModel>> getExcepciones() =>
      _remoteDataSource.getExcepciones();

  @override
  Future<void> deleteGrupo(String id) => _remoteDataSource.deleteGrupo(id);

  @override
  Future<List<SesionModel>> getSesiones({
    String? periodoId,
    String? docenteId,
    String? espacioId,
    String? fecha,
    String? estado,
    String? desde,
    String? hasta,
  }) => _sesiones.getSesiones(
    periodoId: periodoId,
    docenteId: docenteId,
    espacioId: espacioId,
    fecha: fecha,
    estado: estado,
    desde: desde,
    hasta: hasta,
  );

  @override
  Future<void> cancelarSesion({
    required String sesionId,
    required String motivo,
  }) => _sesiones.cancelarSesion(sesionId: sesionId, motivo: motivo);

  @override
  Future<SesionModel> getSesion(String sesionId) =>
      _sesiones.getSesion(sesionId);

  @override
  Future<SesionModel> reasignarAulaSesion({
    required String sesionId,
    required String nuevoEspacioId,
    required CambioSesion cambio,
  }) => _sesiones.reasignarAulaSesion(
    sesionId: sesionId,
    nuevoEspacioId: nuevoEspacioId,
    cambio: cambio,
  );

  @override
  Future<SesionModel> asignarDocenteReemplazo({
    required String sesionId,
    required String docenteId,
    required CambioSesion cambio,
  }) => _sesiones.asignarDocenteReemplazo(
    sesionId: sesionId,
    docenteId: docenteId,
    cambio: cambio,
  );

  @override
  Future<SesionModel> reprogramarSesion({
    required String sesionId,
    required ReprogramacionSesion nueva,
    required CambioSesion cambio,
  }) => _sesiones.reprogramarSesion(
    sesionId: sesionId,
    nueva: nueva,
    cambio: cambio,
  );
}
