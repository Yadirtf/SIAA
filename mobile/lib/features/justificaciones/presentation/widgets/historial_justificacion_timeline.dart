// historial_justificacion_timeline.dart — Transiciones de estado de la justificación
import 'package:flutter/material.dart';

import '../../domain/models/catalogo_justificacion.dart';
import '../../domain/models/justificacion_model.dart';
import 'estado_justificacion_chip.dart';
import 'formato_fechas.dart';

class HistorialJustificacionTimeline extends StatelessWidget {
  final List<EventoJustificacion> historial;

  const HistorialJustificacionTimeline({super.key, required this.historial});

  @override
  Widget build(BuildContext context) {
    if (historial.isEmpty) {
      return Text(
        'Sin movimientos registrados',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < historial.length; i++)
          _evento(historial[i], esUltimo: i == historial.length - 1),
      ],
    );
  }

  Widget _evento(EventoJustificacion e, {required bool esUltimo}) {
    final (_, color) = coloresEstadoJustificacion(e.estado);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Icon(Icons.circle, size: 12, color: color),
              if (!esUltimo)
                Expanded(
                  child: Container(width: 2, color: Colors.grey.shade300),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EstadoJustificacion.etiquetaDe(e.estado),
                    style: TextStyle(fontWeight: FontWeight.w600, color: color),
                  ),
                  if (e.en != null)
                    Text(
                      formatearMomento(e.en!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (e.observaciones != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(e.observaciones!),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
