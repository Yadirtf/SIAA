import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatos.dart';
import '../../data/models/justificacion_catalogos.dart';
import '../../data/models/transicion_model.dart';

/// Línea de tiempo de los cambios de estado de una justificación.
class JustificacionHistorial extends StatelessWidget {
  final List<TransicionModel> historial;
  final String Function(String actorId) nombreActor;

  const JustificacionHistorial({
    super.key,
    required this.historial,
    required this.nombreActor,
  });

  @override
  Widget build(BuildContext context) {
    if (historial.isEmpty) {
      return Text(
        'Sin cambios de estado registrados.',
        style: AppTextStyles.bodySmall,
      );
    }
    return Column(
      children: [
        for (var i = 0; i < historial.length; i++)
          _paso(historial[i], ultimo: i == historial.length - 1),
      ],
    );
  }

  Widget _paso(TransicionModel t, {required bool ultimo}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!ultimo)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    JustificacionCatalogos.etiquetaEstado(t.estado),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${Formatos.fechaHora(t.en)} · ${nombreActor(t.actorId)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  if (t.observaciones != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        t.observaciones!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
