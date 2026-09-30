import 'package:flutter/material.dart';
import '../../bloc/geo_editor_state.dart';

class GeoEditorMapBanners extends StatelessWidget {
  final GeoEditorState state;
  final void Function(int index)? onSelectVertex;

  const GeoEditorMapBanners({
    super.key,
    required this.state,
    this.onSelectVertex,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (state.verticeSeleccionadoIndex != null)
          Positioned(
            top: 12,
            left: 16,
            right: 80,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.black87,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        color: Colors.amberAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vértice #${state.verticeSeleccionadoIndex! + 1} [Lat: ${state.vertices[state.verticeSeleccionadoIndex!][1].toStringAsFixed(6)}, Lon: ${state.vertices[state.verticeSeleccionadoIndex!][0].toStringAsFixed(6)}]: toque el mapa para moverlo.',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onSelectVertex?.call(-1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (state.versionPreview != null)
          Positioned(
            top: state.verticeSeleccionadoIndex != null ? 64 : 12,
            left: 16,
            right: 80,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: Colors.purple.shade900.withOpacity(0.9),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.history_toggle_off_rounded,
                        color: Colors.purpleAccent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Superposición v${state.versionPreview!.version} (${state.versionPreview!.areaMetrosCuadrados.toStringAsFixed(1)} m²)',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
