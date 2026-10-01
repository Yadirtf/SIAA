import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../helpers/filtro_sesiones.dart';

/// Estado de una sesión con color: azul programada, verde realizada, rojo cancelada.
class EstadoSesionChip extends StatelessWidget {
  final String estado;

  const EstadoSesionChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = switch (estado.toUpperCase()) {
      'REALIZADA' => (AppColors.statusSuccessBg, AppColors.statusSuccessText),
      'EN_CURSO' => (AppColors.statusWarningBg, AppColors.statusWarningText),
      'CANCELADA' || 'EXCLUIDA' => (
        AppColors.accentRose.withValues(alpha: 0.12),
        AppColors.accentRose,
      ),
      _ => (AppColors.statusInfoBg, AppColors.statusInfoText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        nombreEstadoSesion(estado),
        style: TextStyle(
          color: texto,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
