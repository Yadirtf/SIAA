import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'academico_models.dart';

class AcademicoRepository {
  final Dio _dio;

  AcademicoRepository({Dio? dio}) : _dio = dio ?? WebApiClient.instance;

  // ─────────────────────────────────────────────
  // Periodos (US-ACA-01)
  // ─────────────────────────────────────────────

  Future<List<PeriodoModel>> listarPeriodos({String? sedeId}) async {
    final res = await _dio.get('/periodos', queryParameters: {
      if (sedeId != null && sedeId.isNotEmpty) 'sedeId': sedeId,
    });
    final list = res.data as List<dynamic>;
    return list
        .map((e) => PeriodoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PeriodoModel> crearPeriodo({
    required String codigo,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required String estado,
    String? sedeId,
    String? codigoExterno,
  }) async {
    final res = await _dio.post('/periodos', data: {
      'codigo': codigo,
      'nombre': nombre,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'estado': estado,
      if (sedeId != null) 'sedeId': sedeId,
      if (codigoExterno != null) 'codigoExterno': codigoExterno,
    });
    return PeriodoModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PeriodoModel> actualizarPeriodo({
    required String id,
    required String codigo,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required String estado,
    String? sedeId,
    String? codigoExterno,
  }) async {
    final res = await _dio.put('/periodos/$id', data: {
      'codigo': codigo,
      'nombre': nombre,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'estado': estado,
      if (sedeId != null) 'sedeId': sedeId,
      if (codigoExterno != null) 'codigoExterno': codigoExterno,
    });
    return PeriodoModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ─────────────────────────────────────────────
  // Estructura Académica (US-ACA-01 AC-04)
  // ─────────────────────────────────────────────

  Future<List<FacultadModel>> listarFacultades({String? sedeId}) async {
    final res = await _dio.get('/facultades', queryParameters: {
      if (sedeId != null && sedeId.isNotEmpty) 'sedeId': sedeId,
    });
    final list = res.data as List<dynamic>;
    return list
        .map((e) => FacultadModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FacultadModel> crearFacultad({
    required String codigo,
    required String nombre,
    String? sedeId,
    String? codigoExterno,
  }) async {
    final res = await _dio.post('/facultades', data: {
      'codigo': codigo,
      'nombre': nombre,
      if (sedeId != null) 'sedeId': sedeId,
      if (codigoExterno != null) 'codigoExterno': codigoExterno,
    });
    return FacultadModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> eliminarFacultad(String id) async {
    await _dio.delete('/facultades/$id');
  }

  Future<List<ProgramaModel>> listarProgramas({String? facultadId}) async {
    final res = await _dio.get('/programas', queryParameters: {
      if (facultadId != null && facultadId.isNotEmpty) 'facultadId': facultadId,
    });
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ProgramaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProgramaModel> crearPrograma({
    required String codigo,
    required String nombre,
    required String facultadId,
    String? codigoExterno,
  }) async {
    final res = await _dio.post('/programas', data: {
      'codigo': codigo,
      'nombre': nombre,
      'facultadId': facultadId,
      if (codigoExterno != null) 'codigoExterno': codigoExterno,
    });
    return ProgramaModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> eliminarPrograma(String id) async {
    await _dio.delete('/programas/$id');
  }

  Future<List<AsignaturaModel>> listarAsignaturas({String? programaId}) async {
    final res = await _dio.get('/asignaturas', queryParameters: {
      if (programaId != null && programaId.isNotEmpty) 'programaId': programaId,
    });
    final list = res.data as List<dynamic>;
    return list
        .map((e) => AsignaturaModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AsignaturaModel> crearAsignatura({
    required String codigo,
    required String nombre,
    required String programaId,
    int creditos = 3,
    String? codigoExterno,
  }) async {
    final res = await _dio.post('/asignaturas', data: {
      'codigo': codigo,
      'nombre': nombre,
      'programaId': programaId,
      'creditos': creditos,
      if (codigoExterno != null) 'codigoExterno': codigoExterno,
    });
    return AsignaturaModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> eliminarAsignatura(String id) async {
    await _dio.delete('/asignaturas/$id');
  }

  Future<List<GrupoModel>> listarGrupos(
      {String? asignaturaId, String? periodoId}) async {
    final res = await _dio.get('/grupos', queryParameters: {
      if (asignaturaId != null && asignaturaId.isNotEmpty)
        'asignaturaId': asignaturaId,
      if (periodoId != null && periodoId.isNotEmpty) 'periodoId': periodoId,
    });
    final list = res.data as List<dynamic>;
    return list
        .map((e) => GrupoModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<GrupoModel> crearGrupo({
    required String numero,
    required String asignaturaId,
    required String periodoId,
    int cupo = 30,
    String? codigoExterno,
  }) async {
    final res = await _dio.post('/grupos', data: {
      'numero': numero,
      'asignaturaId': asignaturaId,
      'periodoId': periodoId,
      'cupo': cupo,
      if (codigoExterno != null) 'codigoExterno': codigoExterno,
    });
    return GrupoModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> eliminarGrupo(String id) async {
    await _dio.delete('/grupos/$id');
  }

  // ─────────────────────────────────────────────
  // Asignaciones (US-ACA-03)
  // ─────────────────────────────────────────────

  Future<List<AsignacionModel>> listarAsignaciones(String periodoId) async {
    final res = await _dio.get('/asignaciones', queryParameters: {
      'periodoId': periodoId,
    });
    final list = res.data as List<dynamic>;
    return list
        .map((e) => AsignacionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AsignacionModel> crearAsignacion({
    required String periodoId,
    required List<String> docenteIds,
    required String docenteNombre,
    required String grupoId,
    required String asignaturaId,
    required String facultadId,
    String? espacioId,
    String? espacioNombre,
    required FranjaModel franja,
    String modalidad = 'PRESENCIAL',
    String? fechaInicio,
    String? fechaFin,
    String? codigoExterno,
  }) async {
    final res = await _dio.post('/asignaciones', data: {
      'periodoId': periodoId,
      'docenteIds': docenteIds,
      'docenteNombre': docenteNombre,
      'grupoId': grupoId,
      'asignaturaId': asignaturaId,
      'facultadId': facultadId,
      if (espacioId != null) 'espacioId': espacioId,
      if (espacioNombre != null) 'espacioNombre': espacioNombre,
      'franja': franja.toJson(),
      'modalidad': modalidad,
      if (fechaInicio != null) 'fechaInicio': fechaInicio,
      if (fechaFin != null) 'fechaFin': fechaFin,
      if (codigoExterno != null) 'codigoExterno': codigoExterno,
    });
    return AsignacionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> eliminarAsignacion(String id) async {
    await _dio.delete('/asignaciones/$id');
  }

  // ─────────────────────────────────────────────
  // Calendario de Excepciones (US-ACA-04)
  // ─────────────────────────────────────────────

  Future<List<ExcepcionModel>> listarExcepciones() async {
    final res = await _dio.get('/calendario-excepciones');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => ExcepcionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ExcepcionModel> crearExcepcion({
    required String nombre,
    required String tipo,
    required String ambito,
    String? ambitoId,
    required String fechaInicio,
    required String fechaFin,
  }) async {
    final res = await _dio.post('/calendario-excepciones', data: {
      'nombre': nombre,
      'tipo': tipo,
      'ambito': ambito,
      if (ambitoId != null) 'ambitoId': ambitoId,
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
    });
    return ExcepcionModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> eliminarExcepcion(String id) async {
    await _dio.delete('/calendario-excepciones/$id');
  }
}
