// filtro_reporte_card.dart — Selección de periodo académico o rango de fechas (RF-REP-001)
import 'package:flutter/material.dart';

import '../../../../core/utils/fechas_es.dart';
import '../../domain/reporte_cumplimiento.dart';

class FiltroReporteCard extends StatelessWidget {
  final List<PeriodoOpcion> periodos;
  final PeriodoOpcion? periodo;
  final DateTime desde;
  final DateTime hasta;
  final ValueChanged<PeriodoOpcion?> onPeriodo;
  final void Function(DateTime, DateTime) onRango;

  const FiltroReporteCard({
    super.key,
    required this.periodos,
    required this.periodo,
    required this.desde,
    required this.hasta,
    required this.onPeriodo,
    required this.onRango,
  });

  Future<void> _elegirRango(BuildContext context) async {
    final hoy = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year - 3),
      lastDate: DateTime(hoy.year + 1),
      initialDateRange: DateTimeRange(start: desde, end: hasta),
    );
    if (rango != null) onRango(rango.start, rango.end);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: [
          if (periodos.isNotEmpty)
            DropdownButtonFormField<PeriodoOpcion?>(
              initialValue: periodo,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Periodo académico',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<PeriodoOpcion?>(
                    value: null, child: Text('Rango de fechas')),
                for (final p in periodos)
                  DropdownMenuItem<PeriodoOpcion?>(
                      value: p, child: Text(p.nombre)),
              ],
              onChanged: onPeriodo,
            ),
          if (periodo == null)
            Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                avatar: const Icon(Icons.date_range_rounded, size: 18),
                label: Text('${fechaCorta(desde)} – ${fechaCorta(hasta)}'),
                onPressed: () => _elegirRango(context),
              ),
            ),
        ],
      ),
    );
  }
}
