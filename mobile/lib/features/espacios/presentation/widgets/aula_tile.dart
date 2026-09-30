// aula_tile.dart — Aula dentro de la jerarquía con estado de su polígono GPS
import 'package:flutter/material.dart';

import '../../../geo_editor/data/espacio_repository.dart';

class AulaTile extends StatelessWidget {
  final EspacioModel espacio;

  /// Abre el editor GPS; null si el rol no tiene aula:editar-geometria.
  final VoidCallback? onEditarPoligono;

  const AulaTile({super.key, required this.espacio, this.onEditarPoligono});

  @override
  Widget build(BuildContext context) {
    final e = espacio;
    final delimitada = e.tieneGeometria;
    final nombre =
        e.nombre.isNotEmpty && e.nombre != e.codigo ? ' · ${e.nombre}' : '';
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 48, right: 8),
      leading: Icon(
        delimitada ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
        color: delimitada ? Colors.green.shade600 : Colors.grey,
        size: 20,
      ),
      title: Text('${e.codigo}$nombre'),
      subtitle: Text(
        '${e.tipo} · ${e.capacidad} puestos · '
        '${delimitada ? 'Polígono ${e.areaMetrosCuadrados.toStringAsFixed(1)} m²' : 'Sin polígono GPS'}',
      ),
      trailing: onEditarPoligono == null
          ? null
          : IconButton(
              icon: const Icon(Icons.edit_location_alt_rounded),
              tooltip: delimitada ? 'Editar polígono' : 'Trazar polígono',
              onPressed: onEditarPoligono,
            ),
    );
  }
}
