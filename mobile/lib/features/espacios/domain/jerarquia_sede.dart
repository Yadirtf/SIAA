// jerarquia_sede.dart — Agrupación Sede → Bloque → Piso → Aula (§9.1 "Espacios (Admin)")
import '../../geo_editor/data/espacio_repository.dart';

class JerarquiaSede {
  final List<BloqueModel> bloques;
  final List<EspacioModel> espacios;

  JerarquiaSede({required List<BloqueModel> bloques, required this.espacios})
      : bloques = [...bloques]..sort((a, b) => a.codigo.compareTo(b.codigo));

  /// Aulas registradas sin bloque (o con un bloque que ya no existe).
  List<EspacioModel> get sinBloque {
    final ids = bloques.map((b) => b.id).toSet();
    return _ordenar(
        espacios.where((e) => e.bloqueId == null || !ids.contains(e.bloqueId)));
  }

  int totalEn(String bloqueId) =>
      espacios.where((e) => e.bloqueId == bloqueId).length;

  /// Aulas del bloque agrupadas por piso (clave null = piso sin informar), pisos ascendentes.
  Map<int?, List<EspacioModel>> porPiso(String bloqueId) {
    final grupos = <int?, List<EspacioModel>>{};
    for (final e in espacios.where((e) => e.bloqueId == bloqueId)) {
      grupos.putIfAbsent(e.piso, () => []).add(e);
    }
    final pisos = grupos.keys.toList()
      ..sort((a, b) => (a ?? 1 << 30).compareTo(b ?? 1 << 30));
    return {for (final p in pisos) p: _ordenar(grupos[p]!)};
  }

  static List<EspacioModel> _ordenar(Iterable<EspacioModel> lista) =>
      lista.toList()..sort((a, b) => a.codigo.compareTo(b.codigo));
}
