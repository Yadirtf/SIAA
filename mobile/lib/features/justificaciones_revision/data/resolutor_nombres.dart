// resolutor_nombres.dart — Resuelve y recuerda nombres de usuarios por id (misma estrategia
// que la consola web: GET /usuarios/:id; si falla, la pantalla muestra un texto genérico).
import 'revision_remote_datasource.dart';

class ResolutorNombres {
  final RevisionRemoteDataSource _remote;
  final Map<String, String> _cache = {};

  ResolutorNombres(this._remote);

  /// Cliente compartido por la bandeja y el detalle.
  RevisionRemoteDataSource get remote => _remote;

  Map<String, String> get conocidos => Map.unmodifiable(_cache);

  Future<Map<String, String>> resolver(Iterable<String> ids) async {
    final pendientes =
        ids.where((id) => id.isNotEmpty && !_cache.containsKey(id)).toSet();
    await Future.wait(pendientes.map((id) async {
      try {
        final nombre = await _remote.nombreUsuario(id);
        if (nombre.isNotEmpty) _cache[id] = nombre;
      } catch (_) {
        // Sin usuario:leer o usuario inexistente: se muestra "Docente".
      }
    }));
    return conocidos;
  }
}
