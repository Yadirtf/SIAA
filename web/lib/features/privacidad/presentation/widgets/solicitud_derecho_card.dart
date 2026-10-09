import 'package:flutter/material.dart';

import '../../../../core/utils/formatos.dart';
import '../../data/models/solicitud_derecho_model.dart';

/// Tarjeta de un caso con titular, plazo, lo pedido y las acciones de atención.
class SolicitudDerechoCard extends StatelessWidget {
  final SolicitudDerechoModel solicitud;
  final VoidCallback? onAsumir;
  final VoidCallback? onAtender;
  final VoidCallback? onDenegar;

  const SolicitudDerechoCard({
    super.key,
    required this.solicitud,
    this.onAsumir,
    this.onAtender,
    this.onDenegar,
  });

  @override
  Widget build(BuildContext context) {
    final s = solicitud;
    final tema = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${s.tipoLegible} · ${s.titularNombre}',
                  style: tema.titleSmall,
                ),
                Chip(label: Text(s.estadoLegible)),
                if (s.vencida)
                  Chip(
                    label: const Text('Plazo vencido'),
                    labelStyle: TextStyle(color: error),
                  ),
              ],
            ),
            Text(s.titularCorreo, style: tema.bodySmall),
            Text(
              'Radicada: ${Formatos.fechaHora(s.radicadaEn)} · '
              'Vence: ${Formatos.fechaHora(s.venceEn)}',
              style: tema.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(s.descripcion),
            if (s.cambios.isNotEmpty)
              Text(
                'Corregir: ${s.cambios.entries.map((e) => '${e.key} → ${e.value}').join(', ')}',
                style: tema.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            for (final e in s.evaluacion)
              Text(
                '${e.eliminable ? 'Se elimina' : 'Se conserva'}: ${e.descripcion} (${e.fundamento})',
                style: tema.bodySmall,
              ),
            if (s.respuesta.isNotEmpty) Text('Respuesta: ${s.respuesta}'),
            if (s.abierta) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (s.estado == 'RADICADA')
                    OutlinedButton(
                      onPressed: onAsumir,
                      child: const Text('Asumir'),
                    ),
                  FilledButton(
                    onPressed: onAtender,
                    child: const Text('Atender'),
                  ),
                  TextButton(
                    onPressed: onDenegar,
                    child: const Text('Denegar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
