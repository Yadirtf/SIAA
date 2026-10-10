// asistencia_asignatura_tile.dart — Porcentaje de una asignatura; resalta en color de
// advertencia cuando está bajo el umbral institucional (US-MAR-13 AC-05).
import 'package:flutter/material.dart';

import '../../domain/asistencia_asignatura.dart';

class AsistenciaAsignaturaTile extends StatelessWidget {
  final AsistenciaAsignatura asistencia;

  const AsistenciaAsignaturaTile({super.key, required this.asistencia});

  @override
  Widget build(BuildContext context) {
    final a = asistencia;
    final esquema = Theme.of(context).colorScheme;
    final gris = esquema.onSurface.withValues(alpha: 0.6);
    final alerta = !a.sinClases && a.bajoUmbral;
    final color = alerta ? Colors.orange.shade900 : Colors.green.shade700;
    final grupo = a.grupo.isEmpty ? '' : 'Grupo ${a.grupo} · ';
    return Card(
      color: alerta ? Colors.orange.shade50 : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text(a.asignatura,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text(
                a.sinClases ? '—' : a.porcentajeTexto,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              a.sinClases
                  ? '${grupo}Sin clases dictadas aún'
                  : '$grupo${a.sesionesAsistidas} de ${a.sesionesDictadas} clases',
              style: TextStyle(color: gris, fontSize: 12),
            ),
            if (!a.sinClases) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (a.porcentaje / 100).clamp(0, 1),
                color: color,
                backgroundColor: esquema.surfaceContainerHighest,
              ),
            ],
            if (alerta) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Estás por debajo del ${a.umbral} % mínimo de asistencia.',
                    style: TextStyle(color: color, fontSize: 12),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}
