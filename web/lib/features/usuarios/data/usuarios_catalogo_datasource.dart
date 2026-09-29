import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../academico/data/academico_remote_datasource.dart';
import '../../geo/data/geo_remote_datasource.dart';
import 'models/catalogo_usuarios_model.dart';
import 'models/rol_opcion_model.dart';

/// Carga los catálogos para roles y ámbitos reutilizando los datasources de
/// geo (sedes, bloques) y académico (facultades).
class UsuariosCatalogoDataSource {
  final ApiClient _client;
  final GeoRemoteDataSource _geo;
  final AcademicoRemoteDataSource _academico;

  UsuariosCatalogoDataSource({
    ApiClient? client,
    GeoRemoteDataSource? geo,
    AcademicoRemoteDataSource? academico,
  }) : _client = client ?? ApiClient(),
       _geo = geo ?? GeoRemoteDataSource(client: client),
       _academico = academico ?? AcademicoRemoteDataSource(client: client);

  Future<List<RolOpcionModel>> getRoles() async {
    final resp = await _client.get(ApiConstants.roles);
    if (resp is! List) return [];
    return resp
        .whereType<Map>()
        .map((e) => RolOpcionModel.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.nombre.isNotEmpty)
        .toList();
  }

  /// Carga todos los catálogos; un fallo parcial no impide usar el resto.
  Future<CatalogoUsuariosModel> cargar() async {
    final errores = <String>[];
    Future<List<T>> intentar<T>(String nombre, Future<List<T>> f) async {
      try {
        return await f;
      } on ApiException catch (e) {
        errores.add('$nombre: ${e.message}');
      } catch (e) {
        errores.add('$nombre: $e');
      }
      return <T>[];
    }

    final roles = intentar('Roles', getRoles());
    final sedes = intentar('Sedes', _geo.getSedes());
    final facultades = intentar('Facultades', _academico.getFacultades());
    final bloques = intentar('Bloques', _geo.getBloques());
    return CatalogoUsuariosModel(
      roles: await roles,
      sedes: await sedes,
      facultades: await facultades,
      bloques: await bloques,
      errores: errores,
    );
  }
}
