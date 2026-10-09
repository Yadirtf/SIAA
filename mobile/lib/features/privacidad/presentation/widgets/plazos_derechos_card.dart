// plazos_derechos_card.dart — Canal de derechos con sus plazos legales (US-LEG-02 AC-04)
import 'package:flutter/material.dart';

import '../../domain/models/canal_derechos.dart';

class PlazosDerechosCard extends StatelessWidget {
  final CanalDerechos canal;

  const PlazosDerechosCard({super.key, required this.canal});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plazos legales de respuesta', style: tema.titleSmall),
            const SizedBox(height: 4),
            for (final p in canal.plazos)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${p.descripcion}: ${p.diasHabiles} días hábiles '
                  '(prorrogables ${p.prorroga}) · ${p.fundamento}',
                  style: tema.bodySmall,
                ),
              ),
            if (canal.contacto.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText('Canal de atención: ${canal.contacto}',
                  style: tema.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            ],
            if (canal.autoridad.isNotEmpty)
              Text(canal.autoridad, style: tema.bodySmall),
          ],
        ),
      ),
    );
  }
}
