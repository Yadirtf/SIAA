import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/academico_models.dart';

class AcademicoRemoteDataSource {
  final ApiClient _client;

  AcademicoRemoteDataSource({ApiClient? client}) : _client = client ?? ApiClient();

  // ─── Periodos ───
  Future<List<PeriodoModel>> getPeriodos() async {
    final response = await _client.get(ApiConstants.periodos);
    if (response is List) {
      return response.map((item) => PeriodoModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<PeriodoModel> createPeriodo({
    required String codigo,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required String estado,
  }) async {
    final response = await _client.post(
      ApiConstants.periodos,
      body: {
        'codigo': codigo,
        'nombre': nombre,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
        'estado': estado,
      },
    );
    return PeriodoModel.fromJson(response as Map<String, dynamic>);
  }

  // ─── Facultades ───
  Future<List<FacultadModel>> getFacultades() async {
    final response = await _client.get(ApiConstants.facultades);
    if (response is List) {
      return response.map((item) => FacultadModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<FacultadModel> createFacultad({
    required String codigo,
    required String nombre,
    String? sedeId,
  }) async {
    final response = await _client.post(
      ApiConstants.facultades,
      body: {
        'codigo': codigo,
        'nombre': nombre,
        if (sedeId != null) 'sedeId': sedeId,
      },
    );
    return FacultadModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteFacultad(String id) async {
    await _client.delete('${ApiConstants.facultades}/$id');
  }

  // ─── Programas ───
  Future<List<ProgramaModel>> getProgramas() async {
    final response = await _client.get(ApiConstants.programas);
    if (response is List) {
      return response.map((item) => ProgramaModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ProgramaModel> createPrograma({
    required String codigo,
    required String nombre,
    required String facultadId,
  }) async {
    final response = await _client.post(
      ApiConstants.programas,
      body: {'codigo': codigo, 'nombre': nombre, 'facultadId': facultadId},
    );
    return ProgramaModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deletePrograma(String id) async {
    await _client.delete('${ApiConstants.programas}/$id');
  }

  // ─── Asignaturas ───
  Future<List<AsignaturaModel>> getAsignaturas() async {
    final response = await _client.get(ApiConstants.asignaturas);
    if (response is List) {
      return response.map((item) => AsignaturaModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<AsignaturaModel> createAsignatura({
    required String codigo,
    required String nombre,
    required String programaId,
    required int creditos,
  }) async {
    final response = await _client.post(
      ApiConstants.asignaturas,
      body: {
        'codigo': codigo,
        'nombre': nombre,
        'programaId': programaId,
        'creditos': creditos,
      },
    );
    return AsignaturaModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAsignatura(String id) async {
    await _client.delete('${ApiConstants.asignaturas}/$id');
  }

  // ─── Grupos ───
  Future<List<GrupoModel>> getGrupos() async {
    final response = await _client.get(ApiConstants.grupos);
    if (response is List) {
      return response.map((item) => GrupoModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<GrupoModel> createGrupo({
    required String numero,
    required String asignaturaId,
    required String periodoId,
    required int cupo,
  }) async {
    final response = await _client.post(
      ApiConstants.grupos,
      body: {
        'numero': numero,
        'asignaturaId': asignaturaId,
        'periodoId': periodoId,
        'cupo': cupo,
      },
    );
    return GrupoModel.fromJson(response as Map<String, dynamic>);
  }

  // ─── Asignaciones ───
  Future<List<AsignacionModel>> getAsignaciones() async {
    final response = await _client.get(ApiConstants.asignaciones);
    if (response is List) {
      return response.map((item) => AsignacionModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<AsignacionModel> createAsignacion(Map<String, dynamic> body) async {
    final response = await _client.post(ApiConstants.asignaciones, body: body);
    return AsignacionModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteAsignacion(String id) async {
    await _client.delete('${ApiConstants.asignaciones}/$id');
  }

  // ─── Excepciones ───
  Future<List<ExcepcionModel>> getExcepciones() async {
    final response = await _client.get(ApiConstants.excepciones);
    if (response is List) {
      return response.map((item) => ExcepcionModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ExcepcionModel> createExcepcion({
    required String nombre,
    required String tipo,
    required String ambito,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    final response = await _client.post(
      ApiConstants.excepciones,
      body: {
        'nombre': nombre,
        'tipo': tipo,
        'ambito': ambito,
        'fechaInicio': fechaInicio,
        'fechaFin': fechaFin,
      },
    );
    return ExcepcionModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteExcepcion(String id) async {
    await _client.delete('${ApiConstants.excepciones}/$id');
  }
}
