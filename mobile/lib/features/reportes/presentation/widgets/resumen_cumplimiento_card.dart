// resumen_cumplimiento_card.dart — Totales del reporte de cumplimiento (RF-REP-001)
import 'package:flutter/material.dart';

import '../../domain/reporte_cumplimiento.dart';

class ResumenCumplimientoCard extends StatelessWidget {
  final ReporteCumplimiento reporte;

  const ResumenCumplimientoCard({super.key, required this.reporte});

  @override
  Widget build(BuildContext context) {
    final t = reporte.totales;
    final metricas = <(String, String)>[
      ('Cumplimiento', '${t.porcentajeCumplimiento.toStringAsFixed(1)} %'),
      ('Sesiones', '${t.sesiones}'),
      (
        'Horas dictadas',
        '${t.horasDictadas.toStringAsFixed(1)} / ${t.horasProgramadas.toStringAsFixed(1)}'
      ),
      ('Tardanzas', '${t.tardanzas}'),
      ('Ausencias injustificadas', '${t.ausenciasInjustificadas}'),
      ('Ausencias justificadas', '${t.ausenciasJustificadas}'),
    ];
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            for (final (etiqueta, valor) in metricas)
              SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(valor,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(etiqueta,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
