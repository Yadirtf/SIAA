import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/adjunto_model.dart';

/// Lista de soportes con acciones para verlos o descargarlos.
class JustificacionSoportes extends StatelessWidget {
  final List<AdjuntoModel> adjuntos;
  final bool habilitado;
  final ValueChanged<AdjuntoModel> onVer;
  final ValueChanged<AdjuntoModel> onDescargar;

  const JustificacionSoportes({
    super.key,
    required this.adjuntos,
    required this.onVer,
    required this.onDescargar,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    if (adjuntos.isEmpty) {
      return Text('Sin soportes adjuntos.', style: AppTextStyles.bodySmall);
    }
    return Column(
      children: adjuntos.map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                a.esPdf
                    ? Icons.picture_as_pdf_rounded
                    : a.esImagen
                    ? Icons.image_rounded
                    : Icons.insert_drive_file_rounded,
                color: a.esPdf ? AppColors.accentRose : AppColors.accentCyan,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.nombre.isEmpty ? a.id : a.nombre,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      '${a.mime} · ${a.tamanoTexto}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ver soporte',
                onPressed: habilitado ? () => onVer(a) : null,
                icon: const Icon(Icons.visibility_outlined),
              ),
              IconButton(
                tooltip: 'Descargar soporte',
                onPressed: habilitado ? () => onDescargar(a) : null,
                icon: const Icon(Icons.download_rounded),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
