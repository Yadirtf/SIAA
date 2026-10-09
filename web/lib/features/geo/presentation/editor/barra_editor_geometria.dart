import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_text_styles.dart';
import 'editor_geometria_cubit.dart';
import 'editor_geometria_state.dart';

/// Acciones del editor de polígono: modo, deshacer/eliminar, área en vivo y
/// guardar. El área usa la fórmula geodésica del backend (US-GEO-07 AC-01).
class BarraEditorGeometria extends StatelessWidget {
  final EditorGeometriaState estado;
  final Widget irACoordenadas;

  const BarraEditorGeometria({
    super.key,
    required this.estado,
    required this.irACoordenadas,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditorGeometriaCubit>();
    final s = estado;
    final editando = s.modo == ModoEditor.editar;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        irACoordenadas,
        SegmentedButton<ModoEditor>(
          segments: const [
            ButtonSegment(
              value: ModoEditor.dibujar,
              icon: Icon(Icons.draw_outlined, size: 18),
              label: Text('Dibujar'),
            ),
            ButtonSegment(
              value: ModoEditor.editar,
              icon: Icon(Icons.open_with_rounded, size: 18),
              label: Text('Editar vértices'),
            ),
          ],
          selected: {s.modo},
          onSelectionChanged: (m) => cubit.cambiarModo(m.first),
        ),
        if (editando)
          OutlinedButton.icon(
            key: const Key('eliminar-vertice'),
            onPressed: s.puedeEliminarVertice ? cubit.eliminarVertice : null,
            icon: const Icon(Icons.remove_circle_outline, size: 18),
            label: const Text('Eliminar vértice'),
          )
        else
          OutlinedButton.icon(
            onPressed: s.vertices.isEmpty ? null : cubit.deshacer,
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Deshacer'),
          ),
        if (s.original.isNotEmpty)
          OutlinedButton.icon(
            onPressed: s.modificado ? cubit.restaurar : null,
            icon: const Icon(Icons.restore_rounded, size: 18),
            label: const Text('Restaurar'),
          ),
        OutlinedButton.icon(
          onPressed: s.vertices.isEmpty ? null : cubit.limpiar,
          icon: const Icon(Icons.layers_clear_outlined, size: 18),
          label: const Text('Borrar todo'),
        ),
        Text(
          '${s.vertices.length} vértices · '
          '${s.areaM2.toStringAsFixed(1)} m²',
          key: const Key('area-en-vivo'),
          style: AppTextStyles.bodyMedium,
        ),
        ElevatedButton.icon(
          onPressed: s.puedeGuardar ? cubit.guardar : null,
          icon: s.guardando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded, size: 18),
          label: const Text('Guardar polígono'),
        ),
      ],
    );
  }
}
