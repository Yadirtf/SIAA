import '../data/academico_remote_datasource.dart';
import '../data/models/academico_models.dart';
import '../data/models/sesion_model.dart';

abstract class AcademicoRepository {
  Future<List<PeriodoModel>> getPeriodos();
  Future<PeriodoModel> createPeriodo({
    required String codigo,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required String estado,
  });

  Future<List<FacultadModel>> getFacultades();
  Future<FacultadModel> createFacultad({
    required String codigo,
    required String nombre,
    String? sedeId,
  });
  Future<void> deleteFacultad(String id);

  Future<List<ProgramaModel>> getProgramas();
  Future<ProgramaModel> createPrograma({
    required String codigo,
    required String nombre,
    required String facultadId,
  });
  Future<void> deletePrograma(String id);

  Future<List<AsignaturaModel>> getAsignaturas();
  Future<AsignaturaModel> createAsignatura({
    required String codigo,
    required String nombre,
    required String programaId,
    required int creditos,
  });
  Future<void> deleteAsignatura(String id);

  Future<List<GrupoModel>> getGrupos();
  Future<GrupoModel> createGrupo({
    required String numero,
    required String asignaturaId,
    required String periodoId,
    required int cupo,
  });
  Future<void> deleteGrupo(String id);

  Future<List<AsignacionModel>> getAsignaciones();
  Future<AsignacionModel> createAsignacion(Map<String, dynamic> body);
  Future<void> deleteAsignacion(String id);

  Future<List<ExcepcionModel>> getExcepciones();

  Future<List<SesionModel>> getSesiones({
    String? periodoId,
    String? docenteId,
    String? espacioId,
    String? fecha,
    String? estado,
    String? desde,
    String? hasta,
  });
  Future<void> cancelarSesion({
    required String sesionId,
    required String motivo,
  });
  Future<SesionModel> reasignarAulaSesion({
    required String sesionId,
    required String nuevoEspacioId,
    String? motivo,
  });
  Future<SesionModel> asignarDocenteReemplazo({
    required String sesionId,
    required String docenteId,
    String? motivo,
  });
}

class AcademicoRepositoryImpl implements AcademicoRepository {
  final AcademicoRemoteDataSource _remoteDataSource;

  AcademicoRepositoryImpl({AcademicoRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? AcademicoRemoteDataSource();

  @override
  Future<List<PeriodoModel>> getPeriodos() => _remoteDataSource.getPeriodos();

  @override
  Future<PeriodoModel> createPeriodo({
    required String codigo,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required String estado,
  }) => _remoteDataSource.createPeriodo(
    codigo: codigo,
    nombre: nombre,
    fechaInicio: fechaInicio,
    fechaFin: fechaFin,
    estado: estado,
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
  }) => _remoteDataSource.getSesiones(
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
  }) => _remoteDataSource.cancelarSesion(sesionId: sesionId, motivo: motivo);

  @override
  Future<SesionModel> reasignarAulaSesion({
    required String sesionId,
    required String nuevoEspacioId,
    String? motivo,
  }) => _remoteDataSource.reasignarAulaSesion(
    sesionId: sesionId,
    nuevoEspacioId: nuevoEspacioId,
    motivo: motivo,
  );

  @override
  Future<SesionModel> asignarDocenteReemplazo({
    required String sesionId,
    required String docenteId,
    String? motivo,
  }) => _remoteDataSource.asignarDocenteReemplazo(
    sesionId: sesionId,
    docenteId: docenteId,
    motivo: motivo,
  );
}
