// filtros_marcajes_bar.dart — Filtros por resultado y rango de fechas (US-MAR-09)
import 'package:flutter/material.dart';

import '../../../../core/utils/fechas_es.dart';
import '../../../marcaje/domain/models/resultado_marcaje.dart';
import '../../domain/filtro_marcajes.dart';

class FiltrosMarcajesBar extends StatelessWidget {
  final FiltroMarcajes filtro;
  final ValueChanged<String?> onResultado;
  final void Function(DateTime? desde, DateTime? hasta) onFechas;

  const FiltrosMarcajesBar({
    super.key,
    required this.filtro,
    required this.onResultado,
    required this.onFechas,
  });

  Future<void> _elegirFechas(BuildContext context) async {
    final ahora = DateTime.now();
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(ahora.year - 2),
      lastDate: ahora,
      initialDateRange: filtro.desde != null && filtro.hasta != null
          ? DateTimeRange(start: filtro.desde!, end: filtro.hasta!)
          : null,
      helpText: 'Rango de fechas',
    );
    if (rango != null) onFechas(rango.start, rango.end);
  }

  @override
  Widget build(BuildContext context) {
    final fechas = filtro.desde == null
        ? 'Todas las fechas'
        : '${fechaCorta(filtro.desde!)} – ${fechaCorta(filtro.hasta ?? filtro.desde!)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              key: const Key('filtro-resultado'),
              initialValue: filtro.resultado,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Resultado',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('Todos')),
                for (final e in etiquetasResultado.entries)
                  DropdownMenuItem<String?>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: onResultado,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InputChip(
              avatar: const Icon(Icons.date_range_rounded, size: 18),
              label: Text(fechas, overflow: TextOverflow.ellipsis),
              onPressed: () => _elegirFechas(context),
              onDeleted:
                  filtro.desde == null ? null : () => onFechas(null, null),
            ),
          ),
        ],
      ),
    );
  }
}
