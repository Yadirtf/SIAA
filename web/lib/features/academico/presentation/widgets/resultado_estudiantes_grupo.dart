import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/estudiante_grupo_model.dart';

/// Resumen del servidor tras guardar: total del grupo e identificadores no
/// aplicados (no encontrados o sin rol de estudiante activo).
class ResultadoEstudiantesGrupoPanel extends StatelessWidget {
  final ResultadoEstudiantesGrupo resultado;

  const ResultadoEstudiantesGrupoPanel({super.key, required this.resultado});

  Widget _lista(String titulo, List<String> items) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      '$titulo (${items.length}): ${items.join(', ')}',
      style: AppTextStyles.bodySmall.copyWith(
        color: AppColors.statusWarningText,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    final conAvisos = r.noEncontrados.isNotEmpty || r.noEstudiantes.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: conAvisos
            ? AppColors.statusWarningBg
            : AppColors.statusSuccessBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cambios guardados. El grupo queda con '
            '${r.estudiantes.length} estudiante(s).',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.statusSuccessText,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (r.noEncontrados.isNotEmpty)
            _lista('No encontrados', r.noEncontrados),
          if (r.noEstudiantes.isNotEmpty)
            _lista('Sin rol de estudiante activo', r.noEstudiantes),
        ],
      ),
    );
  }
}
