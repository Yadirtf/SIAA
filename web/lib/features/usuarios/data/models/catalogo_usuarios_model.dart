import 'package:equatable/equatable.dart';

import '../../../academico/data/models/academico_models.dart';
import '../../../geo/data/models/geo_models.dart';
import 'rol_opcion_model.dart';

/// Catálogos para asignar roles y ámbitos (roles, sedes, facultades, bloques).
/// Cada catálogo se carga por separado; [errores] reúne los que fallaron.
class CatalogoUsuariosModel extends Equatable {
  final List<RolOpcionModel> roles;
  final List<SedeModel> sedes;
  final List<FacultadModel> facultades;
  final List<BloqueModel> bloques;
  final List<String> errores;

  const CatalogoUsuariosModel({
    this.roles = const [],
    this.sedes = const [],
    this.facultades = const [],
    this.bloques = const [],
    this.errores = const [],
  });

  /// Nombre legible de un ámbito a partir de su tipo e id.
  String nombreAmbito(String tipo, String id) {
    String? nombre;
    switch (tipo) {
      case 'SEDE':
        nombre = _buscar(sedes.map((s) => MapEntry(s.id, s.nombre)), id);
      case 'FACULTAD':
        nombre = _buscar(facultades.map((f) => MapEntry(f.id, f.nombre)), id);
      case 'BLOQUE':
        nombre = _buscar(bloques.map((b) => MapEntry(b.id, b.nombre)), id);
    }
    return nombre ?? id;
  }

  static String? _buscar(Iterable<MapEntry<String, String>> items, String id) {
    for (final e in items) {
      if (e.key == id) return e.value;
    }
    return null;
  }

  @override
  List<Object?> get props => [roles, sedes, facultades, bloques, errores];
}
