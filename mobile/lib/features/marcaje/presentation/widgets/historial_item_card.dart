// historial_item_card.dart — Tarjeta de un marcaje del historial propio (US-MAR-08)
import 'package:flutter/material.dart';

import '../../../../core/utils/fechas_es.dart';
import '../../domain/models/marcaje_historial_model.dart';
import 'resultado_badge.dart';

class HistorialItemCard extends StatelessWidget {
  final MarcajeHistorialItem item;

  /// Acción "Justificar"; solo se muestra si el resultado lo permite.
  final VoidCallback? onJustificar;

  const HistorialItemCard({super.key, required this.item, this.onJustificar});

  @override
  Widget build(BuildContext context) {
    final mostrarJustificar = onJustificar != null && item.puedeJustificarse;
    final gris =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          item.tituloSesion,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.tipo == 'SALIDA' ? 'Salida' : 'Entrada'} • '
              '${fechaHora(item.timestampServidor)}',
              style: TextStyle(color: gris, fontSize: 13),
            ),
            if (mostrarJustificar)
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: onJustificar,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Justificar'),
              ),
          ],
        ),
        trailing: ResultadoBadge(item: item),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fila('Resultado:', etiquetaResultado(item.resultado), gris),
                _fila(
                    'Aula:',
                    item.espacioCodigo.isEmpty ? '—' : item.espacioCodigo,
                    gris),
                _fila('Origen:', etiquetaOrigen(item.origen), gris),
                if (item.motivoRechazo != null)
                  _fila('Motivo:', item.motivoRechazo!, gris, alerta: true),
                if (item.motivoAjuste != null)
                  _fila('Ajuste:', item.motivoAjuste!, gris),
                if (item.precisionMetros > 0)
                  _fila('Precisión GPS:',
                      '±${item.precisionMetros.toStringAsFixed(1)} m', gris),
                if (item.distanciaMetros != null)
                  _fila('Distancia al aula:',
                      '${item.distanciaMetros!.toStringAsFixed(1)} m', gris),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(String label, String value, Color gris, {bool alerta = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: gris, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: alerta ? Colors.red.shade700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
