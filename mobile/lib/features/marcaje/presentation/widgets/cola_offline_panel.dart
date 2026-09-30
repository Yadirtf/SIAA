// cola_offline_panel.dart — Detalle de marcajes offline rechazados y fallidos (US-MAR-11)
import 'package:flutter/material.dart';
import '../../domain/models/offline_marcaje_item.dart';
import 'cola_offline_item_tile.dart';

class ColaOfflinePanel extends StatelessWidget {
  final List<OfflineMarcajeItem> rechazados;
  final List<OfflineMarcajeItem> fallidos;
  final ValueChanged<OfflineMarcajeItem>? onJustificar;
  final ValueChanged<OfflineMarcajeItem> onReintentar;

  const ColaOfflinePanel({
    super.key,
    required this.rechazados,
    required this.fallidos,
    required this.onReintentar,
    this.onJustificar,
  });

  @override
  Widget build(BuildContext context) {
    if (rechazados.isEmpty && fallidos.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rechazados.isNotEmpty) ...[
            _titulo('Marcajes offline no aceptados (${rechazados.length})'),
            for (final it in rechazados)
              ColaOfflineItemTile(
                item: it,
                accionLabel: 'Justificar',
                onAccion: onJustificar == null ? null : () => onJustificar!(it),
              ),
          ],
          if (fallidos.isNotEmpty) ...[
            _titulo(
                'Sin sincronizar tras varios intentos (${fallidos.length})'),
            for (final it in fallidos)
              ColaOfflineItemTile(
                item: it,
                accionLabel: 'Reintentar',
                onAccion: () => onReintentar(it),
              ),
          ],
        ],
      ),
    );
  }

  Widget _titulo(String texto) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 2),
        child: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
}
