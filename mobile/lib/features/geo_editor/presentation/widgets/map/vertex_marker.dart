import 'package:flutter/material.dart';
import '../../../domain/models/tagged_vertex.dart';

/// Marcador numerado para representar un vértice del polígono capturado en el mapa.
/// US-GEO-07: Soporta toque para selección, arrastre táctil y pulsación larga para eliminar.
class VertexMarker extends StatelessWidget {
  final int index;
  final TaggedVertex? vertex;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const VertexMarker({
    super.key,
    required this.index,
    this.vertex,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isGps = vertex?.origen == OrigenVertice.gps;
    final baseColor = isGps ? const Color(0xFF2563EB) : const Color(0xFFD97706);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : baseColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.amberAccent : Colors.white,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.amberAccent.withOpacity(0.6)
                  : Colors.black45,
              blurRadius: isSelected ? 8 : 3,
              spreadRadius: isSelected ? 2 : 0,
            ),
          ],
        ),
        child: Text(
          '$index',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
