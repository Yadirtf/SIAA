import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Icono que distingue un valor global de un override por ámbito.
class OrigenIcon extends StatelessWidget {
  final String nivel;

  const OrigenIcon({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final isGlobal = nivel == 'GLOBAL';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isGlobal
            ? AppColors.surfaceMuted
            : AppColors.primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isGlobal ? Icons.public_rounded : Icons.tune_rounded,
        size: 18,
        color: isGlobal ? AppColors.textMuted : AppColors.primaryAccent,
      ),
    );
  }
}

/// Insignia con el nivel de origen del valor efectivo.
class NivelBadge extends StatelessWidget {
  final String nivel;

  const NivelBadge({super.key, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final isGlobal = nivel == 'Global';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGlobal
            ? AppColors.surfaceMuted
            : AppColors.primaryAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGlobal
              ? AppColors.border
              : AppColors.primaryAccent.withOpacity(0.25),
        ),
      ),
      child: Text(
        nivel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isGlobal ? AppColors.textMuted : AppColors.primaryAccent,
        ),
      ),
    );
  }
}
