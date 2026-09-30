import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Panel de estado vacío, error o carga de un listado.
class AvisoPanel extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final Widget? accion;

  const AvisoPanel({
    super.key,
    required this.icono,
    required this.titulo,
    this.detalle = '',
    this.color = AppColors.textMuted,
    this.accion,
  });

  /// Aviso de error con botón "Reintentar".
  factory AvisoPanel.error({
    required String titulo,
    required String detalle,
    required VoidCallback onReintentar,
  }) => AvisoPanel(
    icono: Icons.error_outline_rounded,
    color: AppColors.accentRose,
    titulo: titulo,
    detalle: detalle,
    accion: ElevatedButton.icon(
      onPressed: onReintentar,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Reintentar'),
    ),
  );

  /// Indicador de carga centrado.
  static Widget cargando() => const Center(
    child: Padding(
      padding: EdgeInsets.all(48),
      child: CircularProgressIndicator(color: AppColors.primaryAccent),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 48),
          const SizedBox(height: 12),
          Text(titulo, style: AppTextStyles.h3, textAlign: TextAlign.center),
          if (detalle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (accion != null) ...[const SizedBox(height: 16), accion!],
        ],
      ),
    );
  }
}
