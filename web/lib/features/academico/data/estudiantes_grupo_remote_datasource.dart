import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'models/estudiante_grupo_model.dart';

/// Estudiantes de un grupo (US-MAR-13): consulta y reemplazo de la lista.
class EstudiantesGrupoRemoteDataSource {
  final ApiClient _client;

  EstudiantesGrupoRemoteDataSource({ApiClient? client})
    : _client = client ?? ApiClient();

  Future<List<EstudianteGrupo>> listar(String grupoId) async {
    final r = await _client.get(ApiConstants.estudiantesGrupo(grupoId));
    return (r as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EstudianteGrupo.fromJson)
        .toList();
  }

  /// Reemplaza la lista del grupo por exactamente [identificadores]
  /// (ids de usuario, documentos o correos).
  Future<ResultadoEstudiantesGrupo> reemplazar(
    String grupoId,
    List<String> identificadores,
  ) async {
    final r = await _client.put(
      ApiConstants.estudiantesGrupo(grupoId),
      body: {'estudiantes': identificadores},
    );
    return ResultadoEstudiantesGrupo.fromJson(
      r as Map<String, dynamic>? ?? const {},
    );
  }
}
