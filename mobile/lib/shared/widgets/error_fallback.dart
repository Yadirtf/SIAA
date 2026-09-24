// error_fallback.dart - Pantalla generica de error amigable (sin exponer detalles tecnicos)
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ErrorFallback extends StatelessWidget {
  final String message;

  const ErrorFallback({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: SIAAColors.backgroundLight,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(SIAASpacing.xl),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: SIAAColors.asistenciaAusente,
              size: 48,
            ),
            SizedBox(height: SIAASpacing.md),
            Text(
              'Algo salio mal',
              style: SIAATypography.headlineMedium,
            ),
            SizedBox(height: SIAASpacing.sm),
            Text(
              'Reinicia la aplicacion. Si el problema persiste, contacta a soporte.',
              textAlign: TextAlign.center,
              style: SIAATypography.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
