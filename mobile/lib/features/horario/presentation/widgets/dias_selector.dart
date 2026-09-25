// dias_selector.dart - Selector de días de la semana para el horario (US-ACA-01..09)
import 'package:flutter/material.dart';

class DiasSelector extends StatelessWidget {
  final DateTime fechaSeleccionada;
  final ValueChanged<DateTime> onDiaSeleccionado;

  const DiasSelector({
    super.key,
    required this.fechaSeleccionada,
    required this.onDiaSeleccionado,
  });

  static const _nombresDias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  DateTime _obtenerLunesSemana(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final lunes = _obtenerLunesSemana(fechaSeleccionada);
    final hoy = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          final dia = lunes.add(Duration(days: index));
          final esSeleccionado = dia.year == fechaSeleccionada.year &&
              dia.month == fechaSeleccionada.month &&
              dia.day == fechaSeleccionada.day;
          final esHoy = dia.year == hoy.year &&
              dia.month == hoy.month &&
              dia.day == hoy.day;

          return InkWell(
            onTap: () => onDiaSeleccionado(dia),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: esSeleccionado
                    ? Theme.of(context).primaryColor
                    : (esHoy ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _nombresDias[index],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: esSeleccionado ? FontWeight.bold : FontWeight.normal,
                      color: esSeleccionado
                          ? Colors.white
                          : (esHoy ? Theme.of(context).primaryColor : Colors.grey.shade700),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dia.day}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: esSeleccionado
                          ? Colors.white
                          : (esHoy ? Theme.of(context).primaryColor : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
