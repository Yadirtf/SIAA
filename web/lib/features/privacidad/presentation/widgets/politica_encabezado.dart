import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/politica_privacidad_model.dart';

/// Cabecera del aviso: institución responsable, versión, fecha y contacto.
class PoliticaEncabezado extends StatelessWidget {
  final PoliticaPrivacidadModel politica;

  const PoliticaEncabezado({super.key, required this.politica});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.statusInfoBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                color: AppColors.statusInfoText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  politica.institucion.isEmpty
                      ? 'Aviso de privacidad'
                      : politica.institucion,
                  style: AppTextStyles.h3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _dato('Versión', politica.version),
              if (politica.actualizadaEn.isNotEmpty)
                _dato('Actualizada', politica.actualizadaEn),
              if (politica.contacto.isNotEmpty)
                _dato('Contacto', politica.contacto),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dato(String etiqueta, String valor) {
    return SelectableText.rich(
      TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.statusInfoText,
        ),
        children: [
          TextSpan(
            text: '$etiqueta: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: valor),
        ],
      ),
    );
  }
}
