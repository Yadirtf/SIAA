import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/justificacion_catalogos.dart';

/// Insignia de estado de una justificación.
class JustificacionEstadoBadge extends StatelessWidget {
  final String estado;

  const JustificacionEstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icono) = switch (estado) {
      JustificacionCatalogos.aprobada => (
        AppColors.statusSuccessBg,
        AppColors.statusSuccessText,
        Icons.check_circle_rounded,
      ),
      JustificacionCatalogos.rechazada => (
        AppColors.statusDangerBg,
        AppColors.statusDangerText,
        Icons.cancel_rounded,
      ),
      JustificacionCatalogos.enRevision => (
        AppColors.statusWarningBg,
        AppColors.statusWarningText,
        Icons.hourglass_top_rounded,
      ),
      _ => (
        AppColors.statusInfoBg,
        AppColors.statusInfoText,
        Icons.inbox_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            JustificacionCatalogos.etiquetaEstado(estado),
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
