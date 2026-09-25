import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/dispositivo_model.dart';

class AprobarDispositivoDialog extends StatelessWidget {
  final DispositivoModel dispositivo;
  final VoidCallback onAprobar;

  const AprobarDispositivoDialog({
    super.key,
    required this.dispositivo,
    required this.onAprobar,
  });

  static Future<void> show(
    BuildContext context, {
    required DispositivoModel dispositivo,
    required VoidCallback onAprobar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AprobarDispositivoDialog(
        dispositivo: dispositivo,
        onAprobar: onAprobar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.statusSuccessBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.statusSuccessText,
            ),
          ),
          const SizedBox(width: 12),
          Text('Aprobar Dispositivo Móvil', style: AppTextStyles.h3),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Deseas autorizar este dispositivo para el registro de asistencias docentes y operaciones móviles?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Modelo:', dispositivo.modelo),
                  const SizedBox(height: 6),
                  _row('Sistema Operativo:', dispositivo.so),
                  const SizedBox(height: 6),
                  _row('Versión App:', dispositivo.versionApp),
                  const SizedBox(height: 6),
                  _row('ID Instalación:', dispositivo.instalacionId),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentEmerald,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).pop();
            onAprobar();
          },
          child: const Text('Aprobar Dispositivo'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
