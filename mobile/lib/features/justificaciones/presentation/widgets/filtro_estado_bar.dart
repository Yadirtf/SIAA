// filtro_estado_bar.dart — Filtro horizontal por estado de justificación
import 'package:flutter/material.dart';

import '../../domain/models/catalogo_justificacion.dart';

class FiltroEstadoBar extends StatelessWidget {
  final EstadoJustificacion? seleccionado;
  final ValueChanged<EstadoJustificacion?> onCambiar;

  const FiltroEstadoBar({
    super.key,
    required this.seleccionado,
    required this.onCambiar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _chip('Todas', null),
          for (final e in EstadoJustificacion.values) _chip(e.etiqueta, e),
        ],
      ),
    );
  }

  Widget _chip(String etiqueta, EstadoJustificacion? estado) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(etiqueta),
        selected: seleccionado == estado,
        onSelected: (_) => onCambiar(estado),
      ),
    );
  }
}
