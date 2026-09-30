import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/usuario_model.dart';

/// Insignia de estado: Activo, Inactivo o Bloqueado.
class UsuarioEstadoBadge extends StatelessWidget {
  final UsuarioModel usuario;

  const UsuarioEstadoBadge({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icono) = usuario.bloqueado
        ? (
            AppColors.statusWarningBg,
            AppColors.statusWarningText,
            Icons.lock_clock_rounded,
          )
        : usuario.activo
        ? (
            AppColors.statusSuccessBg,
            AppColors.statusSuccessText,
            Icons.check_circle_rounded,
          )
        : (
            AppColors.statusDangerBg,
            AppColors.statusDangerText,
            Icons.block_rounded,
          );
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
            usuario.estadoTexto,
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
