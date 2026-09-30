import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/entrada_auditoria_model.dart';

/// Bloque monoespaciado y seleccionable con un valor JSON indentado.
class JsonValorView extends StatelessWidget {
  final String titulo;
  final Object? valor;

  const JsonValorView({super.key, required this.titulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final texto = EntradaAuditoriaModel.jsonLegible(valor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: AppTextStyles.label),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 360),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              texto ?? '(sin valor)',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
