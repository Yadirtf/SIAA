// fila_docente_tile.dart — Cumplimiento de un docente con semáforo (RF-REP-001)
import 'package:flutter/material.dart';

import '../../domain/reporte_cumplimiento.dart';

class FilaDocenteTile extends StatelessWidget {
  final FilaCumplimiento fila;

  const FilaDocenteTile({super.key, required this.fila});

  Color _color() {
    final p = fila.porcentajeCumplimiento;
    if (p >= 90) return Colors.green.shade700;
    if (p >= 75) return Colors.amber.shade800;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return ListTile(
      title: Text(fila.nombreVisible),
      subtitle: Text(
        '${fila.sesiones} sesiones · ${fila.tardanzas} tardanzas · '
        '${fila.ausenciasInjustificadas} ausencias injustificadas',
      ),
      trailing: Text(
        '${fila.porcentajeCumplimiento.toStringAsFixed(1)} %',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
