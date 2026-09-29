import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/usuarios_pagina_model.dart';

/// Controles de página anterior/siguiente con el total de resultados.
class UsuariosPaginacion extends StatelessWidget {
  final UsuariosPaginaModel pagina;
  final ValueChanged<int> onPagina;

  const UsuariosPaginacion({
    super.key,
    required this.pagina,
    required this.onPagina,
  });

  @override
  Widget build(BuildContext context) {
    final p = pagina.pagina;
    final totalPaginas = pagina.totalPaginas;
    final resumen = pagina.total != null
        ? '${pagina.total} usuarios · Página $p de $totalPaginas'
        : '${pagina.usuarios.length} usuarios en esta página · Página $p';
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          resumen,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
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
