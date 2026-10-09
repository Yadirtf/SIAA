import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Vértice numerado del polígono. En modo edición se puede arrastrar
/// (US-GEO-07 AC-01), seleccionar con un clic y eliminar con clic derecho o
/// pulsación larga (AC-03, el cubit impide bajar de 3).
class MarcadorVertice extends StatelessWidget {
  final int numero;
  final bool editable;
  final bool seleccionado;
  final VoidCallback? onSeleccionar;
  final VoidCallback? onEliminar;
  final ValueChanged<Offset>? onArrastreInicio;
  final ValueChanged<Offset>? onArrastre;
  final VoidCallback? onArrastreFin;

  const MarcadorVertice({
    super.key,
    required this.numero,
    this.editable = false,
    this.seleccionado = false,
    this.onSeleccionar,
    this.onEliminar,
    this.onArrastreInicio,
    this.onArrastre,
    this.onArrastreFin,
  });

  @override
  Widget build(BuildContext context) {
    final punto = Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: seleccionado ? AppColors.accentRose : AppColors.primaryAccent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Text(
        '$numero',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    if (!editable) return punto;
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Tooltip(
        message: 'Arrastre para mover · clic derecho para eliminar',
        waitDuration: const Duration(milliseconds: 600),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onSeleccionar,
          onSecondaryTap: onEliminar,
          onLongPress: onEliminar,
          onPanStart: (d) => onArrastreInicio?.call(d.globalPosition),
          onPanUpdate: (d) => onArrastre?.call(d.globalPosition),
          onPanEnd: (_) => onArrastreFin?.call(),
          onPanCancel: onArrastreFin,
          child: punto,
        ),
      ),
    );
  }
}
