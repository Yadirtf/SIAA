import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../bloc/sesiones_bloc.dart';

/// Cancela una sesión puntual sin tocar la asignación recurrente (US-ACA-06).
class CancelarSesionDialog extends StatefulWidget {
  final String sesionId;
  const CancelarSesionDialog({super.key, required this.sesionId});

  @override
  State<CancelarSesionDialog> createState() => _CancelarSesionDialogState();
}

class _CancelarSesionDialogState extends State<CancelarSesionDialog> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final motivo = _motivoCtrl.text.trim();
    if (motivo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El motivo de cancelación es obligatorio'),
        ),
      );
      return;
    }
    context.read<SesionesBloc>().add(
      CancelarSesionEvent(sesionId: widget.sesionId, motivo: motivo),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: AppColors.accentRose),
          const SizedBox(width: 8),
          Text('Cancelar Sesión de Clase (US-ACA-06)', style: AppTextStyles.h3),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción cancelará la sesión puntual en el calendario sin afectar la asignación base recurrente.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _motivoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motivo de la cancelación *',
                hintText:
                    'Ej: Evento institucional, mantenimiento de bloque...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRose,
          ),
          onPressed: _submit,
          child: const Text('Confirmar Cancelación'),
        ),
      ],
    );
  }
}
