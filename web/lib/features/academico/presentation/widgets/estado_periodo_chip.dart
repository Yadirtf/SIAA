import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Etiqueta de color con el estado de un periodo académico.
class EstadoPeriodoChip extends StatelessWidget {
  final String estado;

  const EstadoPeriodoChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final activo = estado == 'ACTIVO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? AppColors.statusSuccessBg : AppColors.statusInfoBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        estado,
        style: AppTextStyles.bodySmall.copyWith(
          color: activo
              ? AppColors.statusSuccessText
              : AppColors.statusInfoText,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
