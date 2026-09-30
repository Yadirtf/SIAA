import '../../../core/network/api_exception.dart';
import 'geo_remote_datasource.dart';
import 'models/espacio_opcion.dart';

/// Catálogo de espacios físicos para los selectores de aula. El backend
/// aplica el alcance ABAC (solo devuelve los espacios visibles).
abstract class BuscadorEspacios {
  /// Espacios utilizables (no inactivos), de [sedeId] si se indica.
  Future<List<EspacioOpcion>> listar({String? sedeId});
}

/// Implementación sobre `GET /espacios` y `GET /bloques` (nombre del bloque).
class BuscadorEspaciosRemoto implements BuscadorEspacios {
  final GeoRemoteDataSource _geo;

  BuscadorEspaciosRemoto({GeoRemoteDataSource? geo})
    : _geo = geo ?? GeoRemoteDataSource();

  @override
  Future<List<EspacioOpcion>> listar({String? sedeId}) async {
    final espacios = await _geo.getEspacios(sedeId: sedeId);
    final bloques = await _nombresBloques(sedeId);
    final opciones =
        espacios
            .where((e) => e.estado != 'INACTIVO')
            .map(
              (e) => EspacioOpcion(
                espacio: e,
                bloqueNombre: e.bloqueId == null ? null : bloques[e.bloqueId],
              ),
            )
            .toList()
          ..sort((a, b) => a.espacio.codigo.compareTo(b.espacio.codigo));
    return opciones;
  }

  /// Los nombres de bloque son solo decorativos: si fallan, se omiten.
  Future<Map<String, String>> _nombresBloques(String? sedeId) async {
    try {
      final bloques = await _geo.getBloques(sedeId: sedeId);
      return {for (final b in bloques) b.id: b.nombre};
    } on ApiException {
      return const {};
    }
  }
}
