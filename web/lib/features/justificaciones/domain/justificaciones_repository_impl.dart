import '../../../core/models/pagina.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/archivo_binario.dart';
import '../data/justificaciones_remote_datasource.dart';
import '../data/models/justificacion_model.dart';
import '../data/models/justificaciones_filtro.dart';
import 'justificaciones_repository.dart';

class JustificacionesRepositoryImpl implements JustificacionesRepository {
  final JustificacionesRemoteDataSource _remote;
  final Map<String, String?> _nombres = {};
  bool _sinPermisoUsuarios = false;

  JustificacionesRepositoryImpl({
    JustificacionesRemoteDataSource? remoteDataSource,
  }) : _remote = remoteDataSource ?? JustificacionesRemoteDataSource();

  @override
  Future<Pagina<JustificacionModel>> listar(JustificacionesFiltro filtro) =>
      _remote.listar(filtro);

  @override
  Future<JustificacionModel> obtener(String id) => _remote.obtener(id);

  @override
  Future<JustificacionModel> revisar(
    String id, {
    required String estado,
    String? observaciones,
  }) => _remote.revisar(id, estado: estado, observaciones: observaciones);

  @override
  Future<ArchivoBinario> descargarSoporte(String id, String soporteId) =>
      _remote.descargarSoporte(id, soporteId);

  /// Resuelve y memoriza nombres; tras un 403 deja de consultar para no
  /// repetir peticiones que el rol activo no puede hacer.
  @override
  Future<String?> nombreUsuario(String id) async {
    if (id.isEmpty || _sinPermisoUsuarios) return null;
    if (_nombres.containsKey(id)) return _nombres[id];
    try {
      final nombre = await _remote.nombreUsuario(id);
      return _nombres[id] = nombre.isEmpty ? null : nombre;
    } on AuthException catch (e) {
      if (e.statusCode == 403) _sinPermisoUsuarios = true;
      return null;
    } catch (_) {
      return _nombres[id] = null;
    }
  }
}
