// resultado_badge.dart — Insignia de color por resultado de marcaje (§9.1 "estado por color")
import 'package:flutter/material.dart';

import '../../domain/models/marcaje_historial_model.dart';

/// (fondo, texto, etiqueta) para un marcaje.
(Color, Color, String) coloresResultado(MarcajeHistorialItem item) {
  if (item.anulado) {
    return (Colors.grey.shade200, Colors.grey.shade800, 'ANULADO');
  }
  switch (item.categoria) {
    case CategoriaResultado.aceptado:
      return (Colors.green.shade50, Colors.green.shade800, 'PRESENTE');
    case CategoriaResultado.tardanza:
      return (Colors.amber.shade50, Colors.amber.shade900, 'TARDANZA');
    case CategoriaResultado.ausencia:
      return (Colors.orange.shade50, Colors.orange.shade800, 'AUSENCIA');
    case CategoriaResultado.rechazado:
      return (Colors.red.shade50, Colors.red.shade800, 'RECHAZADO');
    case CategoriaResultado.desconocido:
      return (Colors.grey.shade200, Colors.grey.shade800, 'SIN RESULTADO');
  }
}

class ResultadoBadge extends StatelessWidget {
  final MarcajeHistorialItem item;

  const ResultadoBadge({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final (fondo, texto, etiqueta) = coloresResultado(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        etiqueta,
        style:
            TextStyle(color: texto, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
