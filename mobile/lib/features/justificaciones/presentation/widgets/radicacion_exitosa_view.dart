// radicacion_exitosa_view.dart — Confirmación tras radicar una justificación
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/justificacion_model.dart';

class RadicacionExitosaView extends StatelessWidget {
  final Justificacion justificacion;
  final VoidCallback onVerMisJustificaciones;

  const RadicacionExitosaView({
    super.key,
    required this.justificacion,
    required this.onVerMisJustificaciones,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: SIAASpacing.xl),
        Icon(Icons.task_alt_rounded, size: 64, color: Colors.green.shade600),
        const SizedBox(height: SIAASpacing.md),
        Text('Justificación radicada', style: SIAATypography.titleLarge),
        const SizedBox(height: SIAASpacing.sm),
        Text(
          'Tu solicitud (${justificacion.tipoEtiqueta}) quedó en estado '
          '${justificacion.estadoEtiqueta.toLowerCase()}. Te notificaremos '
          'cuando sea revisada.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: SIAASpacing.lg),
        FilledButton(
          onPressed: onVerMisJustificaciones,
          child: const Text('Ver mis justificaciones'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Volver'),
        ),
      ],
    );
  }
}
