import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/academico/data/estudiantes_grupo_remote_datasource.dart';
import 'package:siaa_web/features/academico/data/models/estudiante_grupo_model.dart';

const anaGrupo = EstudianteGrupo(
  id: 'u1',
  nombre: 'Ana Pérez',
  correo: 'ana@uni.edu.co',
  documento: '1001',
);
const luisGrupo = EstudianteGrupo(
  id: 'u2',
  nombre: 'Luis Gómez',
  correo: 'luis@uni.edu.co',
);

/// Fuente falsa: devuelve [iniciales] y registra lo enviado en el PUT.
class EstudiantesGrupoDsFalso extends EstudiantesGrupoRemoteDataSource {
  List<EstudianteGrupo> iniciales;
  List<String>? enviados;
  ResultadoEstudiantesGrupo? respuesta;
  String? errorAlGuardar;

  EstudiantesGrupoDsFalso({this.iniciales = const [anaGrupo, luisGrupo]});

  @override
  Future<List<EstudianteGrupo>> listar(String grupoId) async => iniciales;

  @override
  Future<ResultadoEstudiantesGrupo> reemplazar(
    String grupoId,
    List<String> identificadores,
  ) async {
    enviados = identificadores;
    if (errorAlGuardar != null) {
      throw ApiException(message: errorAlGuardar!, statusCode: 422);
    }
    return respuesta ??
        ResultadoEstudiantesGrupo(
          estudiantes: iniciales,
          noEncontrados: const [],
        );
  }
}
