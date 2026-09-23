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

          // ─── Tira de Vértices Registrados con Coordenadas Reales (Lat/Lon) ─
          if (state.vertices.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pin_drop, size: 14, color: SIAAColors.primary600),
                    const SizedBox(width: 4),
                    Text(
                      'Puntos registrados (${state.isClosed && state.vertices.length > 3 ? state.vertices.length - 1 : state.vertices.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: SIAAColors.neutral800,
                      ),
                    ),
                  ],
                ),
                Text(
                  state.isClosed ? 'Polígono cerrado' : 'Abierto (en trazado)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: state.isClosed ? SIAAColors.asistenciaPresente : SIAAColors.neutral500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.isClosed && state.vertices.length > 3
                    ? state.vertices.length - 1
                    : state.vertices.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final v = state.vertices[index];
                  final lon = v[0];
                  final lat = v[1];
                  final isSelected = state.verticeSeleccionadoIndex == index;
                  final isGps = state.verticesEtiquetados.length > index &&
                      state.verticesEtiquetados[index].origen == OrigenVertice.gps;

                  return InkWell(
                    onTap: () => onSelectVertex?.call(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFCBD5E1),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isGps ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${index + 1} ${isGps ? "GPS" : "Manual"}',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 10, color: Color(0xFFD97706)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lat: ${lat.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'Lon: ${lon.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
                      children: [
                        const Icon(Icons.touch_app, size: 18, color: SIAAColors.primary600),
                        const SizedBox(width: 6),
                        Text(
                          state.isClosed
                              ? (state.verticeSeleccionadoIndex != null
                                  ? 'Toque el mapa para reubicar vértice'
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
