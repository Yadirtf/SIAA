import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/geo_models.dart';

/// Indicador compacto de los métodos de verificación complementaria
/// configurados en un espacio (p. ej. "WIFI · QR").
class VerificacionIndicador extends StatelessWidget {
  final VerificacionEspacioModel verificacion;

  const VerificacionIndicador({super.key, required this.verificacion});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verificación complementaria configurada',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.statusSuccessBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_user_outlined,
              size: 13,
              color: AppColors.statusSuccessText,
            ),
            const SizedBox(width: 4),
            Text(
              verificacion.metodos.join(' · '),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.statusSuccessText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
