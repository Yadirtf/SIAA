import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../helpers/filtro_sesiones.dart';

/// Elige el rango de fechas de la tabla: semana anterior/siguiente, volver a
/// la semana actual o un rango libre en el calendario.
class RangoSemanaSelector extends StatelessWidget {
  final DateTimeRange rango;
  final ValueChanged<DateTimeRange> onCambio;

  const RangoSemanaSelector({
    super.key,
    required this.rango,
    required this.onCambio,
  });

  void _mover(int dias) => onCambio(
    DateTimeRange(
      start: rango.start.add(Duration(days: dias)),
      end: rango.end.add(Duration(days: dias)),
    ),
  );

  Future<void> _elegir(BuildContext context) async {
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: rango,
      helpText: 'Rango de fechas de las sesiones',
      saveText: 'Aplicar',
    );
    if (elegido != null) onCambio(elegido);
  }

  @override
  Widget build(BuildContext context) {
    final dias = rango.end.difference(rango.start).inDays + 1;
    final esEstaSemana = rango == semanaDe(DateTime.now());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Semana anterior',
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => _mover(-dias),
        ),
        OutlinedButton.icon(
          onPressed: () => _elegir(context),
          icon: const Icon(Icons.date_range_rounded, size: 18),
          label: Text(
            '${fechaLegible(rango.start)} - ${fechaLegible(rango.end)}',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        IconButton(
          tooltip: 'Semana siguiente',
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => _mover(dias),
        ),
        if (!esEstaSemana)
          TextButton(
            onPressed: () => onCambio(semanaDe(DateTime.now())),
            child: const Text('Esta semana'),
          ),
      ],
    );
  }
}
