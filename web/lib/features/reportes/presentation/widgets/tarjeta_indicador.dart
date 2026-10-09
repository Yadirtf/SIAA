import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Tarjeta compacta con un indicador numérico y su etiqueta.
class TarjetaIndicador extends StatelessWidget {
  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color color;
  final String? detalle;

  const TarjetaIndicador({
    super.key,
    required this.icono,
    required this.etiqueta,
    required this.valor,
    this.color = AppColors.primaryAccent,
    this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valor, style: AppTextStyles.h2.copyWith(color: color)),
                Text(etiqueta, style: AppTextStyles.bodySmall),
                if (detalle != null)
                  Text(
                    detalle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
