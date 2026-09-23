import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/tagged_vertex.dart';
import '../../bloc/geo_editor_state.dart';

class GeoEditorActionButtons extends StatelessWidget {
  final GeoEditorState state;
  final VoidCallback? onDeshacer;
  final VoidCallback? onCapturar;
  final VoidCallback? onCerrarPoligono;
  final VoidCallback? onGuardar;

  const GeoEditorActionButtons({
    super.key,
    required this.state,
    this.onDeshacer,
    this.onCapturar,
    this.onCerrarPoligono,
    this.onGuardar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo, size: 18),
                label: const Text('Deshacer'),
                onPressed: state.canUndo ? onDeshacer : null,
              ),
            ),
            const SizedBox(width: 8),
            if (state.modoCaptura == ModoCapturaEditor.recorrido)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SIAAColors.primary600,
                    foregroundColor: Colors.white,
                  ),
                  icon: state.status == GeoEditorStatus.capturing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_location_alt, size: 18),
                  label: Text(
                    state.status == GeoEditorStatus.capturing
                        ? 'Muestreando...'
                        : 'Capturar Vértice',
                  ),
                  onPressed: state.canCapture ? onCapturar : null,
                ),
              )
            else
              Expanded(
                flex: 2,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SIAAColors.primary200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app, size: 18, color: SIAAColors.primary600),
                      const SizedBox(width: 6),
                      Text(
                        state.isClosed
                            ? (state.verticeSeleccionadoIndex != null
                                ? 'Toque el mapa para reubicar'
                                : 'Toque un vértice o arista para ajustar')
                            : 'Toque mapa para marcar',
                        style: const TextStyle(
                          color: SIAAColors.primary700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            if (!state.isClosed)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SIAAColors.neutral800,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Cerrar Polígono'),
                  onPressed: state.canClose ? onCerrarPoligono : null,
                ),
              ),
            if (state.isClosed)
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SIAAColors.asistenciaPresente,
                    foregroundColor: Colors.white,
                  ),
                  icon: state.status == GeoEditorStatus.saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload, size: 18),
                  label: Text(
                    state.status == GeoEditorStatus.saving
                        ? 'Guardando...'
                        : 'Guardar Geometría',
                  ),
                  onPressed: state.status != GeoEditorStatus.saving ? onGuardar : null,
                  ),
              ),
          ],
        ),
      ],
    );
  }
}
