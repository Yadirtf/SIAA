import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Modal informativo cuando un dispositivo móvil requiere autorización administrativa (US-AUT-03 AC-03).
class DispositivoPendienteDialog extends StatelessWidget {
  final String mensaje;

  const DispositivoPendienteDialog({
    super.key,
    required this.mensaje,
  });

  static Future<void> show(BuildContext context, {required String mensaje}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DispositivoPendienteDialog(mensaje: mensaje),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: SIAASpacing.radiusMd,
      ),
      icon: Container(
        padding: const EdgeInsets.all(SIAASpacing.md),
        decoration: BoxDecoration(
          color: SIAAColors.asistenciaTardanza.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.phonelink_lock_rounded,
          color: SIAAColors.asistenciaTardanza,
          size: 40,
        ),
      ),
      title: Text(
        'Dispositivo no Reconocido',
        textAlign: TextAlign.center,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.textTheme.bodySmall?.color,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: SIAAColors.primary500,
            shape: const RoundedRectangleBorder(
              borderRadius: SIAASpacing.radiusSm,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
