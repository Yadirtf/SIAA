import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class DispositivoMetricasHeader extends StatelessWidget {
  final int total;
  final int aprobados;
  final int pendientes;
  final int revocados;

  const DispositivoMetricasHeader({
    super.key,
    required this.total,
    required this.aprobados,
    required this.pendientes,
    required this.revocados,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 700;
        final cardWidth = isSmall
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _card(
              width: cardWidth,
              title: 'Total Registrados',
              count: total,
              icon: Icons.devices_other_rounded,
              color: AppColors.primaryAccent,
            ),
            _card(
              width: cardWidth,
              title: 'Aprobados (Confiables)',
              count: aprobados,
              icon: Icons.verified_user_rounded,
              color: AppColors.accentEmerald,
            ),
            _card(
              width: cardWidth,
              title: 'Pendientes Autorización',
              count: pendientes,
              icon: Icons.pending_actions_rounded,
              color: AppColors.accentAmber,
              isHighlight: pendientes > 0,
            ),
            _card(
              width: cardWidth,
              title: 'Revocados',
              count: revocados,
              icon: Icons.block_rounded,
              color: AppColors.accentRose,
            ),
          ],
        );
      },
    );
  }

  Widget _card({
    required double width,
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? color.withOpacity(0.6) : AppColors.border,
          width: isHighlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: isHighlight
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
