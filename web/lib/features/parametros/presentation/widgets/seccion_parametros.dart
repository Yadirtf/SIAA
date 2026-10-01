import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/catalogo_parametros.dart';
import '../../domain/models/parametro_model.dart';
import 'parametro_card.dart';

const _iconos = {
  GrupoParametro.entrada: Icons.login_rounded,
  GrupoParametro.salida: Icons.logout_rounded,
  GrupoParametro.ubicacion: Icons.gps_fixed_rounded,
  GrupoParametro.seguridad: Icons.verified_user_outlined,
  GrupoParametro.alertas: Icons.notifications_active_outlined,
  GrupoParametro.privacidad: Icons.privacy_tip_outlined,
};

/// Tarjeta con los parámetros de un grupo (por ejemplo "Ubicación y GPS").
class SeccionParametros extends StatelessWidget {
  final GrupoParametro grupo;
  final List<ParametroEfectivoModel> parametros;
  final String ambito;
  final String ambitoId;
  final bool guardando;

  const SeccionParametros({
    super.key,
    required this.grupo,
    required this.parametros,
    required this.ambito,
    required this.ambitoId,
    required this.guardando,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.surfaceMuted,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Icon(_iconos[grupo], color: AppColors.primaryAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grupo.titulo,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(grupo.descripcion, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final p in parametros)
            ParametroCard(
              key: ValueKey('${p.clave}-${p.nivel}-${p.valor}'),
              parametro: p,
              ambitoDestino: ambito,
              ambitoDestinoId: ambitoId,
              isSaving: guardando,
            ),
        ],
      ),
    );
  }
}
