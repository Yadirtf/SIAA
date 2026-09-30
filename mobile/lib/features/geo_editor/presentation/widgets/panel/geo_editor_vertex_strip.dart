import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/tagged_vertex.dart';
import '../../bloc/geo_editor_state.dart';

class GeoEditorVertexStrip extends StatelessWidget {
  final GeoEditorState state;
  final ValueChanged<int>? onSelectVertex;

  const GeoEditorVertexStrip({
    super.key,
    required this.state,
    this.onSelectVertex,
  });

  @override
  Widget build(BuildContext context) {
    if (state.vertices.isEmpty) return const SizedBox.shrink();

    final distinctCount = state.isClosed && state.vertices.length > 3
        ? state.vertices.length - 1
        : state.vertices.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.pin_drop,
                    size: 14, color: SIAAColors.primary600),
                const SizedBox(width: 4),
                Text(
                  'Puntos registrados ($distinctCount)',
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
                color: state.isClosed
                    ? SIAAColors.asistenciaPresente
                    : SIAAColors.neutral500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: distinctCount,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF8FAFC),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isGps
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFD97706),
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
                            const Icon(Icons.edit,
                                size: 10, color: Color(0xFFD97706)),
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
    );
  }
}
