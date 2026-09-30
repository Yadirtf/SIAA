import '../../../core/models/opcion_catalogo.dart';
import '../../academico/data/academico_remote_datasource.dart';
import '../../geo/data/buscador_espacios.dart';
import '../../geo/data/geo_remote_datasource.dart';

/// Opciones legibles para elegir el objetivo de un nivel de parámetros
/// (sede, facultad, bloque o aula) sin escribir ids.
abstract class FuenteOpcionesAmbito {
  /// Opciones del [nivel] (`SEDE`, `FACULTAD`, `BLOQUE`, `AULA`);
  /// `GLOBAL` u otro nivel sin catálogo devuelve una lista vacía.
  Future<List<OpcionCatalogo>> opciones(String nivel);
}

/// Implementación con los catálogos del API (el backend aplica el alcance).
class OpcionesAmbitoRemoto implements FuenteOpcionesAmbito {
  final GeoRemoteDataSource _geo;
  final AcademicoRemoteDataSource _academico;
  final BuscadorEspacios _espacios;

  OpcionesAmbitoRemoto({
    GeoRemoteDataSource? geo,
    AcademicoRemoteDataSource? academico,
    BuscadorEspacios? espacios,
  }) : _geo = geo ?? GeoRemoteDataSource(),
       _academico = academico ?? AcademicoRemoteDataSource(),
       _espacios = espacios ?? BuscadorEspaciosRemoto(geo: geo);

  static String _codigoNombre(String codigo, String nombre) =>
      [codigo, nombre].where((t) => t.isNotEmpty).join(' · ');

  @override
  Future<List<OpcionCatalogo>> opciones(String nivel) async {
    switch (nivel) {
      case 'SEDE':
        final sedes = await _geo.getSedes();
        return sedes
            .map(
              (s) => OpcionCatalogo(
                id: s.id,
                etiqueta: _codigoNombre(s.codigo, s.nombre),
                detalle: s.direccion,
              ),
            )
            .toList();
      case 'FACULTAD':
        final facultades = await _academico.getFacultades();
        return facultades
            .map(
              (f) => OpcionCatalogo(
                id: f.id,
                etiqueta: _codigoNombre(f.codigo, f.nombre),
              ),
            )
            .toList();
      case 'BLOQUE':
        final bloques = await _geo.getBloques();
        return bloques
            .map(
              (b) => OpcionCatalogo(
                id: b.id,
                etiqueta: _codigoNombre(b.codigo, b.nombre),
                detalle: b.pisos.isEmpty ? null : 'Pisos ${b.pisos.join(', ')}',
              ),
            )
            .toList();
      case 'AULA':
        final espacios = await _espacios.listar();
        return espacios
            .map(
              (e) => OpcionCatalogo(
                id: e.id,
                etiqueta: e.etiqueta,
                detalle: e.detalle,
              ),
            )
            .toList();
      default:
        return const [];
    }
  }
}
