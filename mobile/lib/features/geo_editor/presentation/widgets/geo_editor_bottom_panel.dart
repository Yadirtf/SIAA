import 'package:flutter/material.dart';
import '../bloc/geo_editor_state.dart';
import 'panel/geo_editor_action_buttons.dart';
import 'panel/geo_editor_metrics_bar.dart';
import 'panel/geo_editor_vertex_strip.dart';

/// Panel inferior que muestra las métricas geodésicas en tiempo real
/// y los botones de acción para captura, edición y persistencia del polígono.
class GeoEditorBottomPanel extends StatelessWidget {
  final GeoEditorState state;
  final VoidCallback? onDeshacer;
  final VoidCallback? onCapturar;
  final VoidCallback? onCerrarPoligono;
  final VoidCallback? onGuardar;
  final ValueChanged<int>? onSelectVertex;

  const GeoEditorBottomPanel({
    super.key,
    required this.state,
    this.onDeshacer,
    this.onCapturar,
    this.onCerrarPoligono,
    this.onGuardar,
    this.onSelectVertex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GeoEditorMetricsBar(state: state),
          GeoEditorVertexStrip(
            state: state,
            onSelectVertex: onSelectVertex,
          ),
          const SizedBox(height: 12),
          GeoEditorActionButtons(
            state: state,
            onDeshacer: onDeshacer,
            onCapturar: onCapturar,
            onCerrarPoligono: onCerrarPoligono,
            onGuardar: onGuardar,
          ),
        ],
      ),
    );
  }
}
