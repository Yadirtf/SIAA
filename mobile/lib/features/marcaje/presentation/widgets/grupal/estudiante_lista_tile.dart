// estudiante_lista_tile.dart — Fila de un estudiante en la lista manual: interruptor
// presente/ausente, o su registro actual bloqueado si ya marcó (US-MAR-14 AC-04).
import 'package:flutter/material.dart';

import '../../../domain/models/lista_manual_model.dart';
import 'etiqueta_registro.dart';

class EstudianteListaTile extends StatelessWidget {
  final EstudianteListaManual estudiante;
  final bool presente;
  final bool habilitado;
  final ValueChanged<bool> onCambio;

  const EstudianteListaTile({
    super.key,
    required this.estudiante,
    required this.presente,
    required this.onCambio,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    final gris = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final e = estudiante;
    final inicial = e.nombre.isEmpty ? '?' : e.nombre[0].toUpperCase();
    if (e.bloqueado) {
      final origen = etiquetaOrigen(e.origen);
      return ListTile(
        leading: CircleAvatar(child: Text(inicial)),
        title: Text(e.nombre),
        subtitle: Text(
          origen == null ? 'Ya tiene registro' : 'Ya marcó $origen',
          style: TextStyle(color: gris, fontSize: 12),
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(etiquetaResultado(e.resultado),
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Icon(Icons.lock_outline_rounded, size: 18, color: gris),
        ]),
      );
    }
    return SwitchListTile(
      secondary: CircleAvatar(child: Text(inicial)),
      title: Text(e.nombre),
      subtitle: Text(
        presente ? 'Presente' : 'Ausente',
        style: TextStyle(
          color: presente ? Colors.green.shade700 : Colors.orange.shade800,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      value: presente,
      onChanged: habilitado ? onCambio : null,
    );
  }
}
