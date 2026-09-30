// semana_header.dart - Navegación entre semanas de Mi Horario (§9.1)
import 'package:flutter/material.dart';
import '../../../../core/utils/fechas_es.dart';

class SemanaHeader extends StatelessWidget {
  final DateTime lunes;
  final VoidCallback onAnterior;
  final VoidCallback onSiguiente;

  const SemanaHeader({
    super.key,
    required this.lunes,
    required this.onAnterior,
    required this.onSiguiente,
  });

  /// "22 – 27 sep 2026" (lunes a sábado).
  static String rango(DateTime lunes) {
    final sabado = DateTime(lunes.year, lunes.month, lunes.day + 5);
    final inicio =
        lunes.month == sabado.month ? '${lunes.day}' : diaMesCorto(lunes);
    return '$inicio – ${diaMesCorto(sabado)} ${sabado.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Semana anterior',
          onPressed: onAnterior,
        ),
        Expanded(
          child: Text(
            'Semana del ${rango(lunes)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Semana siguiente',
          onPressed: onSiguiente,
        ),
      ],
    );
  }
}
