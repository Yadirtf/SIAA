// sede_expansion_tile.dart — Nodo Sede → Bloque → Piso → Aula de la jerarquía física
import 'package:flutter/material.dart';

import '../../../geo_editor/data/espacio_repository.dart';
import '../../domain/jerarquia_sede.dart';
import '../cubit/espacios_jerarquia_cubit.dart';
import 'aula_tile.dart';

class SedeExpansionTile extends StatelessWidget {
  final SedeModel sede;
  final DetalleSede? detalle;
  final VoidCallback onExpandir;
  final void Function(EspacioModel)? onEditarPoligono;

  const SedeExpansionTile({
    super.key,
    required this.sede,
    required this.detalle,
    required this.onExpandir,
    this.onEditarPoligono,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.apartment_rounded),
        title: Text(sede.nombre.isNotEmpty ? sede.nombre : sede.codigo,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(sede.codigo),
        onExpansionChanged: (abierta) {
          if (abierta) onExpandir();
        },
        children: _contenido(),
      ),
    );
  }

  List<Widget> _contenido() {
    final d = detalle;
    if (d == null || d.estado == EstadoCarga.cargando) {
      return const [
        Padding(padding: EdgeInsets.all(12), child: LinearProgressIndicator())
      ];
    }
    if (d.estado == EstadoCarga.error) {
      return [
        ListTile(
          leading: const Icon(Icons.error_outline, color: Colors.red),
          title: Text(d.error ?? 'No se pudieron cargar las aulas.'),
          trailing: TextButton(
              onPressed: onExpandir, child: const Text('Reintentar')),
        ),
      ];
    }
    final j = d.jerarquia!;
    if (j.bloques.isEmpty && j.espacios.isEmpty) {
      return const [
        ListTile(title: Text('Esta sede aún no tiene bloques ni aulas'))
      ];
    }
    return [
      for (final b in j.bloques) _bloque(j, b),
      if (j.sinBloque.isNotEmpty)
        ExpansionTile(
          leading: const Icon(Icons.domain_disabled_rounded),
          title: Text('Aulas sin bloque (${j.sinBloque.length})'),
          children: [for (final e in j.sinBloque) _aula(e)],
        ),
    ];
  }

  Widget _bloque(JerarquiaSede j, BloqueModel b) {
    final pisos = j.porPiso(b.id);
    final nombre =
        b.nombre.isNotEmpty && b.nombre != b.codigo ? ' — ${b.nombre}' : '';
    return ExpansionTile(
      tilePadding: const EdgeInsets.only(left: 24, right: 16),
      leading: const Icon(Icons.domain_rounded),
      title: Text('${b.codigo}$nombre'),
      subtitle: Text('${j.totalEn(b.id)} aulas'),
      children: pisos.isEmpty
          ? const [
              ListTile(title: Text('Sin aulas registradas en este bloque'))
            ]
          : [
              for (final entry in pisos.entries)
                ExpansionTile(
                  tilePadding: const EdgeInsets.only(left: 40, right: 16),
                  title: Text(entry.key == null
                      ? 'Piso sin informar'
                      : 'Piso ${entry.key}'),
                  subtitle: Text('${entry.value.length} aulas'),
                  children: [for (final e in entry.value) _aula(e)],
                ),
            ],
    );
  }

  Widget _aula(EspacioModel e) => AulaTile(
        espacio: e,
        onEditarPoligono:
            onEditarPoligono == null ? null : () => onEditarPoligono!(e),
      );
}
