// cola_offline_item_tile.dart — Fila de un marcaje offline rechazado o fallido (US-MAR-11)
import 'package:flutter/material.dart';
import '../../../../core/utils/fechas_es.dart';
import '../../domain/models/offline_marcaje_item.dart';

class ColaOfflineItemTile extends StatelessWidget {
  final OfflineMarcajeItem item;
  final String accionLabel;
  final VoidCallback? onAccion;

  const ColaOfflineItemTile({
    super.key,
    required this.item,
    required this.accionLabel,
    this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    final esRechazo = item.estado == EstadoSincronizacion.rechazado;
    final color = esRechazo ? Colors.red.shade700 : Colors.orange.shade800;
    final fecha = diaMesHora(item.request.timestampDispositivo);
    final mensaje = esRechazo
        ? (item.resultadoServidor?.mensaje.isNotEmpty == true
            ? item.resultadoServidor!.mensaje
            : 'Marcaje no aceptado (${item.resultadoServidor?.resultado ?? '-'})')
        : (item.errorMensaje ?? 'No fue posible sincronizar');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            esRechazo ? Icons.cancel_outlined : Icons.sync_problem_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.request.tipo} · $fecha',
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
                Text(mensaje, style: const TextStyle(fontSize: 12)),
                if (item.requiereRevision)
                  Text(
                    'Requiere revisión: hora del dispositivo desfasada',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          if (onAccion != null)
            TextButton(onPressed: onAccion, child: Text(accionLabel)),
        ],
      ),
    );
  }
}
