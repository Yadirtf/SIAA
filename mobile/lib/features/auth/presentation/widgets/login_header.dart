import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: SIAAColors.primary500,
            borderRadius: SIAASpacing.radiusMd,
            boxShadow: [
              BoxShadow(
                color: SIAAColors.primary500.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: SIAASpacing.md),
        Text(
          'SIAA',
          style: SIAATypography.displayLarge.copyWith(
            color: SIAAColors.primary500,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: SIAASpacing.xs),
        Text(
          'Sistema de Asistencia Académica',
          style: SIAATypography.bodyMedium.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
