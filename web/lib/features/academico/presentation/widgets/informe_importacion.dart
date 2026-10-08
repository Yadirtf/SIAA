import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/importacion_model.dart';

/// Informe por fila de una carga masiva: resumen, umbral y filas con errores o
/// advertencias (US-ACA-07 AC-01, AC-04, AC-05).
class InformeImportacion extends StatelessWidget {
  final PreviewImportacionModel preview;

  const InformeImportacion({super.key, required this.preview});

  @override
  Widget build(BuildContext context) {
    final conNovedad = preview.filas
        .where((f) => f.errores.isNotEmpty || f.advertencias.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip(
              'Total filas: ${preview.totalFilas}',
              AppColors.statusInfoBg,
              AppColors.statusInfoText,
            ),
            _chip(
              'Válidas: ${preview.filasValidas}',
              AppColors.statusSuccessBg,
              AppColors.statusSuccessText,
            ),
            _chip(
              'Con error: ${preview.filasConError}',
              AppColors.statusWarningBg,
              AppColors.statusWarningText,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          preview.superaUmbral
              ? 'Las filas con error superan el umbral de '
                    '${preview.umbralErroresPct.toStringAsFixed(1)} %: corrija el '
                    'archivo; al aplicar no se guardaría nada.'
              : 'Al aplicar se guardan las filas válidas y se omiten las que '
                    'tienen error (umbral ${preview.umbralErroresPct.toStringAsFixed(1)} %).',
          style: AppTextStyles.bodySmall.copyWith(
            color: preview.superaUmbral ? AppColors.accentRose : null,
          ),
        ),
        if (conNovedad.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
            ),
            child: ListView(
              shrinkWrap: true,
              children: conNovedad.map(_fila).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _fila(FilaImportacionModel f) {
    final error = f.errores.isNotEmpty;
    return ListTile(
      dense: true,
      leading: Icon(
        error ? Icons.error_outline : Icons.info_outline,
        color: error ? AppColors.accentRose : Colors.amber,
        size: 18,
      ),
      title: Text(
        'Fila ${f.numeroFila} · ${f.asignaturaCodigo} grupo ${f.grupoCodigo}',
      ),
      subtitle: Text([...f.errores, ...f.advertencias].join('\n')),
    );
  }

  Widget _chip(String text, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
}
