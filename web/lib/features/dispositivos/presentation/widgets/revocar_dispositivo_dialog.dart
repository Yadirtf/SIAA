import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/models/dispositivo_model.dart';

class RevocarDispositivoDialog extends StatefulWidget {
  final DispositivoModel dispositivo;
  final ValueChanged<String?> onRevocar;

  const RevocarDispositivoDialog({
    super.key,
    required this.dispositivo,
    required this.onRevocar,
  });

  static Future<void> show(
    BuildContext context, {
    required DispositivoModel dispositivo,
    required ValueChanged<String?> onRevocar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => RevocarDispositivoDialog(
        dispositivo: dispositivo,
        onRevocar: onRevocar,
      ),
    );
  }

  @override
  State<RevocarDispositivoDialog> createState() =>
      _RevocarDispositivoDialogState();
}

class _RevocarDispositivoDialogState extends State<RevocarDispositivoDialog> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
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
              color: AppColors.statusDangerBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.block_rounded,
              color: AppColors.statusDangerText,
            ),
          ),
          const SizedBox(width: 12),
          Text('Revocar Acceso del Dispositivo', style: AppTextStyles.h3),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción desconectará y bloqueará este dispositivo para el usuario. No podrá registrar asistencias hasta que sea reactivado.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Dispositivo: ${widget.dispositivo.modelo} (${widget.dispositivo.so})',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motivoCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Motivo de revocación (opcional)',
                hintText: 'Ej: Extravío de equipo, cambio de teléfono, sospecha de anomalía...',
                border: OutlineInputBorder(),
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
            backgroundColor: AppColors.accentRose,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final motivo = _motivoCtrl.text.trim();
            Navigator.of(context).pop();
            widget.onRevocar(motivo.isNotEmpty ? motivo : null);
          },
          child: const Text('Revocar Acceso'),
        ),
      ],
    );
  }
}
