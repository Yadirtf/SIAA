import '../data/models/academico_models.dart';
import '../data/models/cambio_sesion.dart';
import '../data/models/sesion_model.dart';

export '../data/models/cambio_sesion.dart';
export 'academico_repository_impl.dart';

/// Operaciones de la estructura académica, asignaciones y sesiones.
abstract class AcademicoRepository {
  Future<List<PeriodoModel>> getPeriodos();
  Future<PeriodoModel> createPeriodo({
    required String codigo,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required String estado,
    bool confirmarSolapamiento = false,
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
  Future<SesionModel> getSesion(String sesionId);
  Future<SesionModel> reasignarAulaSesion({
    required String sesionId,
    required String nuevoEspacioId,
    required CambioSesion cambio,
  });
  Future<SesionModel> asignarDocenteReemplazo({
    required String sesionId,
    required String docenteId,
    required CambioSesion cambio,
  });
  Future<SesionModel> reprogramarSesion({
    required String sesionId,
    required ReprogramacionSesion nueva,
    required CambioSesion cambio,
  });
}
