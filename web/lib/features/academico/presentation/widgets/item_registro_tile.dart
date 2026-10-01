import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Fila de un registro editable (facultad, programa, sede…) con acciones de
/// editar y, si se indica, eliminar.
class ItemRegistroTile extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String? subtitulo;
  final String nombreTipo;
  final VoidCallback onEditar;
  final VoidCallback? onEliminar;
  final List<Widget> accionesExtra;

  const ItemRegistroTile({
    super.key,
    required this.icono,
    required this.color,
    required this.titulo,
    required this.nombreTipo,
    required this.onEditar,
    this.subtitulo,
    this.onEliminar,
    this.accionesExtra = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icono, color: color),
        title: Text(titulo, style: AppTextStyles.h3),
        subtitle: subtitulo == null
            ? null
            : Text(subtitulo!, style: AppTextStyles.bodyMedium),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...accionesExtra,
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar $nombreTipo',
              onPressed: onEditar,
            ),
            if (onEliminar != null)
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.accentRose,
                ),
                tooltip: 'Eliminar $nombreTipo',
                onPressed: onEliminar,
              ),
          ],
        ),
      ),
    );
  }
}
