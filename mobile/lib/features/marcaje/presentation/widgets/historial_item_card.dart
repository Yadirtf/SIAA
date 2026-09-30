// historial_item_card.dart — Tarjeta de un marcaje del historial (US-MAR-08)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/marcaje_historial_model.dart';

class HistorialItemCard extends StatelessWidget {
  final MarcajeHistorialItem item;

  /// Acción "Justificar"; solo se muestra si el resultado lo permite.
  final VoidCallback? onJustificar;

  const HistorialItemCard({super.key, required this.item, this.onJustificar});

  @override
  Widget build(BuildContext context) {
    final (badgeBg, badgeFg, badgeText) = _insignia();
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');
    final mostrarJustificar = onJustificar != null && item.puedeJustificarse;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          item.asignatura,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.tipo} • ${dateFormat.format(item.timestampServidor)}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
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
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              color: badgeFg,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fila('Aula / Espacio:', item.espacioCodigo),
                _fila('Origen:', item.origen),
                if (item.motivoRechazo != null)
                  _fila('Motivo:', item.motivoRechazo!, alerta: true),
                if (item.precisionMetros > 0)
                  _fila('Precisión GPS:',
                      '±${item.precisionMetros.toStringAsFixed(1)}m'),
                if (item.distanciaMetros != null)
                  _fila('Distancia al aula:',
                      '${item.distanciaMetros!.toStringAsFixed(1)}m'),
                _fila(
                  'Coordenadas:',
                  '[${item.longitud.toStringAsFixed(5)}, '
                      '${item.latitud.toStringAsFixed(5)}]',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _insignia() {
    if (item.anulado) {
      return (Colors.grey.shade200, Colors.grey.shade800, 'ANULADO');
    }
    if (item.esAceptado) {
      return (Colors.green.shade50, Colors.green.shade800, 'ACEPTADO');
    }
    if (item.esAusencia) {
      return (Colors.orange.shade50, Colors.orange.shade800, 'AUSENCIA');
    }
    return (Colors.red.shade50, Colors.red.shade800, 'RECHAZADO');
  }

  Widget _fila(String label, String value, {bool alerta = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: alerta ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
