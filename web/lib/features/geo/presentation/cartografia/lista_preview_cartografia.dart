import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/preview_cartografia_model.dart';

/// Informe por elemento de la previsualización (US-GEO-11 AC-01): válido o
/// no, errores de validación y advertencias como coordenadas invertidas
/// (AC-04) o códigos que ya existen.
class ListaPreviewCartografia extends StatelessWidget {
  final PreviewCartografiaModel previa;

  const ListaPreviewCartografia({super.key, required this.previa});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Formato ${previa.formato.toUpperCase()}: ${previa.validos} válidos, '
          '${previa.invalidos} con errores.',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        for (final e in previa.elementos) _Elemento(item: e),
      ],
    );
  }
}

class _Elemento extends StatelessWidget {
  final ItemCartografiaModel item;
  const _Elemento({required this.item});

  @override
  Widget build(BuildContext context) {
    final avisos = [
      ...item.errores.map((t) => (t, AppColors.accentRose)),
      ...item.advertencias.map((t) => (t, AppColors.textMuted)),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.valido
                ? (item.coordenadasInvertidas
                      ? Icons.swap_horiz_rounded
                      : Icons.check_circle_outline)
                : Icons.error_outline,
            size: 18,
            color: item.valido ? AppColors.accentEmerald : AppColors.accentRose,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.indice}. ${item.codigo} — ${item.nombre} '
                  '(${item.tipo})',
                  style: AppTextStyles.bodyMedium,
                ),
                for (final (texto, color) in avisos)
                  Text(
                    texto,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: color,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
