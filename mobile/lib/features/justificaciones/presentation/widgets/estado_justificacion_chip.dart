// estado_justificacion_chip.dart — Insignia de color por estado de justificación
import 'package:flutter/material.dart';

import '../../domain/models/catalogo_justificacion.dart';

/// Colores (fondo, texto) para cada estado del flujo de revisión.
(Color, Color) coloresEstadoJustificacion(String codigo) {
  switch (EstadoJustificacion.desdeCodigo(codigo)) {
    case EstadoJustificacion.radicada:
      return (Colors.blue.shade50, Colors.blue.shade800);
    case EstadoJustificacion.enRevision:
      return (Colors.amber.shade50, Colors.amber.shade900);
    case EstadoJustificacion.aprobada:
      return (Colors.green.shade50, Colors.green.shade800);
    case EstadoJustificacion.rechazada:
      return (Colors.red.shade50, Colors.red.shade800);
    case null:
      return (Colors.grey.shade200, Colors.grey.shade800);
  }
}

class EstadoJustificacionChip extends StatelessWidget {
  final String estado;

  const EstadoJustificacionChip({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final (fondo, texto) = coloresEstadoJustificacion(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        EstadoJustificacion.etiquetaDe(estado).toUpperCase(),
        style: TextStyle(
          color: texto,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
