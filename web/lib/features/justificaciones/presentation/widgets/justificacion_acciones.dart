import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/justificacion_catalogos.dart';

/// Botones de decisión según el estado actual de la justificación.
class JustificacionAcciones extends StatelessWidget {
  final String estado;
  final bool habilitado;
  final VoidCallback onRevision;
  final VoidCallback onAprobar;
  final VoidCallback onRechazar;

  const JustificacionAcciones({
    super.key,
    required this.estado,
    required this.onRevision,
    required this.onAprobar,
    required this.onRechazar,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!JustificacionCatalogos.esPendiente(estado)) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (estado == JustificacionCatalogos.radicada)
          OutlinedButton.icon(
            onPressed: habilitado ? onRevision : null,
            icon: const Icon(Icons.hourglass_top_rounded, size: 18),
            label: const Text('Pasar a revisión'),
          ),
        OutlinedButton.icon(
          onPressed: habilitado ? onRechazar : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.statusDangerText,
          ),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text('Rechazar'),
        ),
        ElevatedButton.icon(
          onPressed: habilitado ? onAprobar : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentEmerald,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
          label: const Text('Aprobar'),
        ),
      ],
    );
  }
}
