// dias_selector.dart - Chips de lunes a sábado con número de clases (US-ACA-01..09, §9.1)
import 'package:flutter/material.dart';

class DiasSelector extends StatelessWidget {
  final DateTime lunes;
  final DateTime fechaSeleccionada;
  final ValueChanged<DateTime> onDiaSeleccionado;

  /// Número de sesiones por día (null mientras carga).
  final int Function(DateTime dia)? conteo;
  final DateTime? hoy;

  const DiasSelector({
    super.key,
    required this.lunes,
    required this.fechaSeleccionada,
    required this.onDiaSeleccionado,
    this.conteo,
    this.hoy,
  });

  static const nombresDias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  static bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final primario = Theme.of(context).colorScheme.primary;
    final ahora = hoy ?? DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: List.generate(nombresDias.length, (i) {
          final dia = DateTime(lunes.year, lunes.month, lunes.day + i);
          final seleccionado = _mismoDia(dia, fechaSeleccionada);
          final esHoy = _mismoDia(dia, ahora);
          final n = conteo?.call(dia);
          final colorTexto =
              seleccionado ? Colors.white : (esHoy ? primario : null);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onDiaSeleccionado(dia),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: seleccionado
                        ? primario
                        : (esHoy ? primario.withValues(alpha: 0.1) : null),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(nombresDias[i],
                          style: TextStyle(fontSize: 12, color: colorTexto)),
                      Text('${dia.day}',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colorTexto)),
                      Text(
                        n == null ? ' ' : (n == 0 ? '—' : '$n'),
                        key: Key('conteo-dia-$i'),
                        style: TextStyle(fontSize: 10, color: colorTexto),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
