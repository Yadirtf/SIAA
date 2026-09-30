import 'package:flutter/material.dart';

import '../models/pagina.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Controles de página anterior/siguiente con el total de resultados.
class PaginacionControles extends StatelessWidget {
  final Pagina<Object?> pagina;
  final String sustantivo;
  final ValueChanged<int> onPagina;

  const PaginacionControles({
    super.key,
    required this.pagina,
    required this.onPagina,
    this.sustantivo = 'registros',
  });

  @override
  Widget build(BuildContext context) {
    final p = pagina.pagina;
    final resumen = pagina.total != null
        ? '${pagina.total} $sustantivo · Página $p de ${pagina.totalPaginas}'
        : '${pagina.items.length} $sustantivo en esta página · Página $p';
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            resumen,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Página anterior',
          onPressed: p > 1 ? () => onPagina(p - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          tooltip: 'Página siguiente',
          onPressed: pagina.hayMas ? () => onPagina(p + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}
