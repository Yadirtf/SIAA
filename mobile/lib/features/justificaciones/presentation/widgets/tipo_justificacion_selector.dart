// tipo_justificacion_selector.dart — Selector del tipo de justificación
import 'package:flutter/material.dart';

import '../../domain/models/catalogo_justificacion.dart';

class TipoJustificacionSelector extends StatelessWidget {
  final TipoJustificacion? seleccionado;
  final bool habilitado;
  final ValueChanged<TipoJustificacion> onSeleccionar;

  const TipoJustificacionSelector({
    super.key,
    required this.seleccionado,
    required this.onSeleccionar,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final tipo in TipoJustificacion.values)
          ChoiceChip(
            label: Text(tipo.etiqueta),
            selected: tipo == seleccionado,
            onSelected: habilitado ? (_) => onSeleccionar(tipo) : null,
          ),
      ],
    );
  }
}
