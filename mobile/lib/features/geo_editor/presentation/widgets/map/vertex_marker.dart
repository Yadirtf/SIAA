import 'package:flutter/material.dart';
import '../../../domain/models/tagged_vertex.dart';

/// Marcador numerado para representar un vértice del polígono capturado en el mapa.
class VertexMarker extends StatelessWidget {
  final int index;
  final TaggedVertex? vertex;

  const VertexMarker({
    super.key,
    required this.index,
    this.vertex,
  });

  @override
  Widget build(BuildContext context) {
    final isGps = vertex?.origen == OrigenVertice.gps;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isGps ? const Color(0xFF2563EB) : const Color(0xFFD97706),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 3)],
      ),
      child: Text(
        '$index',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
