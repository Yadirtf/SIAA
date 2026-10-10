// captura_pendiente_tile.dart — Una captura offline con su estado y acciones (US-GEO-10)
import 'package:flutter/material.dart';

import '../../../../core/geo/offline_cartografia_service.dart';
import '../../../../core/utils/fechas_es.dart';

class CapturaPendienteTile extends StatelessWidget {
  final CapturaOfflineEspacio captura;
  final VoidCallback onCorregir;
  final VoidCallback onResolverConflicto;
  final VoidCallback onDescartar;

  const CapturaPendienteTile({
    super.key,
    required this.captura,
    required this.onCorregir,
    required this.onResolverConflicto,
    required this.onDescartar,
  });

  static const _etiquetas = {
    EstadoSincronizacion.pendienteSincronizacion: 'Pendiente de sincronización',
    EstadoSincronizacion.sincronizado: 'Sincronizada',
    EstadoSincronizacion.errorValidacion: 'Rechazada por el servidor',
    EstadoSincronizacion.conflicto: 'En conflicto',
  };

  static const _iconos = {
    EstadoSincronizacion.pendienteSincronizacion: Icons.cloud_upload_outlined,
    EstadoSincronizacion.sincronizado: Icons.cloud_done_outlined,
    EstadoSincronizacion.errorValidacion: Icons.error_outline_rounded,
    EstadoSincronizacion.conflicto: Icons.call_split_rounded,
  };

  Color _color(BuildContext context) => switch (captura.estado) {
        EstadoSincronizacion.sincronizado => Colors.green.shade700,
        EstadoSincronizacion.errorValidacion =>
          Theme.of(context).colorScheme.error,
        EstadoSincronizacion.conflicto => Colors.orange.shade800,
        EstadoSincronizacion.pendienteSincronizacion =>
          Theme.of(context).colorScheme.primary,
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final titulo = captura.espacioCodigo.isNotEmpty
        ? '${captura.espacioCodigo} · ${captura.espacioNombre}'
        : captura.espacioId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(_iconos[captura.estado], color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(titulo,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              '${_etiquetas[captura.estado]} · ${captura.vertices.length} vértices · '
              'capturada ${diaMesHora(captura.capturadoEn)}',
              style: TextStyle(color: color, fontSize: 12),
            ),
            if (captura.mensajeError != null) ...[
              const SizedBox(height: 4),
              Text(captura.mensajeError!, style: const TextStyle(fontSize: 13)),
            ],
            Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: _acciones()),
          ],
        ),
      ),
    );
  }

  List<Widget> _acciones() {
    switch (captura.estado) {
      case EstadoSincronizacion.errorValidacion:
        return [
          TextButton(onPressed: onDescartar, child: const Text('Descartar')),
          TextButton(
              onPressed: onCorregir,
              child: const Text('Corregir en el editor')),
        ];
      case EstadoSincronizacion.conflicto:
        return [
          TextButton(
              onPressed: onResolverConflicto,
              child: const Text('Resolver conflicto')),
        ];
      case EstadoSincronizacion.sincronizado:
        return [
          TextButton(
              onPressed: onDescartar, child: const Text('Quitar de la lista')),
        ];
      case EstadoSincronizacion.pendienteSincronizacion:
        return const [];
    }
  }
}
