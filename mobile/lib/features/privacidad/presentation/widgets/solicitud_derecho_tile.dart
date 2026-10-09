// solicitud_derecho_tile.dart — Caso del titular con estado, plazo y respuesta (US-LEG-02 AC-02)
import 'package:flutter/material.dart';

import '../../../../core/utils/fechas_es.dart';
import '../../domain/models/solicitud_derecho.dart';

class SolicitudDerechoTile extends StatelessWidget {
  final SolicitudDerecho solicitud;

  const SolicitudDerechoTile({super.key, required this.solicitud});

  Color _color(BuildContext context) => switch (solicitud.estado) {
        'ATENDIDA' => Colors.green.shade700,
        'DENEGADA' => Theme.of(context).colorScheme.error,
        _ => Theme.of(context).colorScheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final tema = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(s.tipoLegible, style: tema.titleSmall)),
              Chip(
                label: Text(s.estadoLegible),
                labelStyle: TextStyle(color: _color(context), fontSize: 12),
                visualDensity: VisualDensity.compact,
              ),
            ]),
            if (s.radicadaEn != null)
              Text('Radicada el ${fechaCorta(s.radicadaEn!)}',
                  style: tema.bodySmall),
            if (s.abierta && s.venceEn != null)
              Text('Plazo de respuesta: ${fechaCorta(s.venceEn!)}',
                  style: tema.bodySmall),
            if (s.cambios.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  s.cambios.entries
                      .map((e) => '${e.key}: ${e.value}')
                      .join(' · '),
                  style: tema.bodySmall,
                ),
              ),
            if (s.respuesta.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child:
                    Text('Respuesta: ${s.respuesta}', style: tema.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}
