// placeholder_screen.dart - Estado vacio informativo para rutas en desarrollo.
// Paso 2 Requisito 6: si la ruta no esta implementada, mostrar estado vacio
// informativo en vez de fallar (desarrollo incremental).
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Pantalla generica de "en desarrollo" para rutas aun no implementadas.
/// Reemplazar por el widget real cuando se implemente cada modulo.
class PlaceholderScreen extends StatelessWidget {
  final String titulo;
  final String descripcion;
  final IconData icono;

  const PlaceholderScreen({
    super.key,
    required this.titulo,
    this.descripcion = 'Esta pantalla estara disponible proximamente.',
    this.icono = Icons.construction_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(SIAASpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? SIAAColors.primary900.withValues(alpha: 0.4)
                        : SIAAColors.primary50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icono,
                    size: 40,
                    color: SIAAColors.primary500,
                  ),
                ),
                const SizedBox(height: SIAASpacing.lg),
                Text(
                  titulo,
                  style: SIAATypography.headlineMedium.copyWith(
                    color:
                        isDark ? SIAAColors.neutral100 : SIAAColors.neutral800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: SIAASpacing.sm),
                Text(
                  descripcion,
                  style: SIAATypography.bodyMedium.copyWith(
                    color:
                        isDark ? SIAAColors.neutral400 : SIAAColors.neutral500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
