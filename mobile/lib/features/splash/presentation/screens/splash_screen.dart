// splash_screen.dart - Pantalla de splash institucional con animacion de carga
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: SIAAColors.primary500,
                borderRadius: SIAASpacing.radiusLg,
                boxShadow: [
                  BoxShadow(
                    color: SIAAColors.primary500.withValues(alpha: 0.25),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: SIAASpacing.md),
            Text(
              'SIAA',
              style: SIAATypography.displayLarge.copyWith(
                color: SIAAColors.primary500,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: SIAASpacing.xl),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(SIAAColors.primary500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
