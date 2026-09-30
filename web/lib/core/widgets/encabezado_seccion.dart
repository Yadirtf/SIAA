import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Encabezado de pantalla: icono, título, subtítulo y acciones a la derecha.
class EncabezadoSeccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final List<Widget> acciones;

  const EncabezadoSeccion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icono, color: AppColors.primaryAccent, size: 26),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppTextStyles.h1),
                Text(
                  subtitulo,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (acciones.isNotEmpty)
          Wrap(spacing: 10, runSpacing: 8, children: acciones),
      ],
    );
  }
}
