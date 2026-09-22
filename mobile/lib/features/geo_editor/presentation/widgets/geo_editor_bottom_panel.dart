import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/tagged_vertex.dart';
import '../bloc/geo_editor_state.dart';

/// Panel inferior que muestra las métricas geodésicas en tiempo real
/// y los botones de acción para captura, edición y persistencia del polígono.
class GeoEditorBottomPanel extends StatelessWidget {
  final GeoEditorState state;
  final VoidCallback? onDeshacer;
  final VoidCallback? onCapturar;
  final VoidCallback? onCerrarPoligono;
  final VoidCallback? onGuardar;

  const GeoEditorBottomPanel({
    super.key,
    required this.state,
    this.onDeshacer,
    this.onCapturar,
    this.onCerrarPoligono,
    this.onGuardar,
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
          // ─── Métricas Geodésicas ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricaItem(
                label: 'Área estimada (AC-06)',
                valor: '${state.areaCalculadaM2.toStringAsFixed(1)} m²',
                icono: Icons.square_foot,
                color: SIAAColors.primary600,
              ),
              _MetricaItem(
                label: 'Perímetro',
                valor: '${state.perimetroMetros.toStringAsFixed(1)} m',
                icono: Icons.timeline,
                color: SIAAColors.neutral700,
              ),
              _MetricaItem(
                label: 'Precisión prom.',
                valor: state.precisionPromedioCalculada != null
                    ? '${state.precisionPromedioCalculada!.toStringAsFixed(1)} m'
                    : 'N/A',
                icono: Icons.gps_fixed,
                color: state.precisionPromedioCalculada != null &&
                        state.precisionPromedioCalculada! <= 10
                    ? SIAAColors.asistenciaPresente
                    : SIAAColors.neutral500,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ─── Botones de Acción Primarios (Deshacer / Capturar) ─────────────
          Row(
            children: [
              // AC-05: Deshacer vértice
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Deshacer'),
                  onPressed: state.canUndo ? onDeshacer : null,
                ),
              ),
              const SizedBox(width: 8),

              // AC-01: Capturar vértice por GPS (en modo recorrido)
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
                      children: const [
                        Icon(Icons.touch_app, size: 18, color: SIAAColors.primary600),
                        SizedBox(width: 6),
                        Text(
                          'Toque mapa para marcar',
                          style: TextStyle(
                            color: SIAAColors.primary700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ─── Cierre y Guardado ───────────────────────────────────────────
          Row(
            children: [
              // AC-06: Cerrar polígono
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

              // AC-07: Guardar en el backend
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
      ),
    );
  }
}

class _MetricaItem extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color color;

  const _MetricaItem({
    required this.label,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: color, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: SIAAColors.neutral500)),
            Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }
}
