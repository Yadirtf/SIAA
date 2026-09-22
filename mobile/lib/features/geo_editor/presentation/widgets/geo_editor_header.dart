import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/tagged_vertex.dart';
import '../bloc/geo_editor_state.dart';
import 'gps_traffic_light_badge.dart';

/// Encabezado del editor cartográfico:
/// - Selector de modo (GPS Recorrido vs Toque Mapa)
/// - Barra de telemetría y método de captura
/// - Banner contextual para modo de toque en mapa
class GeoEditorHeader extends StatelessWidget {
  final GeoEditorState state;
  final ValueChanged<ModoCapturaEditor> onModoChanged;

  const GeoEditorHeader({
    super.key,
    required this.state,
    required this.onModoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── Selector de modo de captura (RF-GEO-002 vs RF-GEO-004) ──────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SegmentedButton<ModoCapturaEditor>(
                  segments: const [
                    ButtonSegment<ModoCapturaEditor>(
                      value: ModoCapturaEditor.recorrido,
                      icon: Icon(Icons.directions_walk, size: 16),
                      label: Text('GPS Recorrido'),
                    ),
                    ButtonSegment<ModoCapturaEditor>(
                      value: ModoCapturaEditor.mapa,
                      icon: Icon(Icons.touch_app, size: 16),
                      label: Text('Toque Mapa'),
                    ),
                  ],
                  selected: {state.modoCaptura},
                  onSelectionChanged: (Set<ModoCapturaEditor> newSelection) {
                    onModoChanged(newSelection.first);
                  },
                ),
              ),
            ],
          ),
        ),

        // ─── Barra de estado de telemetría y método de captura ─────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (state.modoCaptura == ModoCapturaEditor.recorrido)
                GpsTrafficLightBadge(
                  status: state.accuracyStatus,
                  accuracyMetros: state.currentPosition?.accuracy,
                )
              else
                const _ModoMapaBadge(),
              Row(
                children: [
                  _MetodoBadge(metodo: state.metodoCapturaEfectivo),
                  const SizedBox(width: 8),
                  Text(
                    '${state.vertices.length} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: SIAAColors.neutral700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ─── Banner informativo en modo mapa ──────────────────────────────
        if (state.modoCaptura == ModoCapturaEditor.mapa)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: const Color(0xFFFEF3C7), // Amber 100
            child: Row(
              children: const [
                Icon(Icons.touch_app, size: 16, color: Color(0xFFB45309)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modo Toque en Mapa: Toque directamente sobre el mapa satelital para posicionar cada esquina del aula.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ModoMapaBadge extends StatelessWidget {
  const _ModoMapaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.map, size: 14, color: Colors.cyanAccent),
          SizedBox(width: 6),
          Text(
            'Mapa Interactivo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.cyanAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetodoBadge extends StatelessWidget {
  final String metodo;

  const _MetodoBadge({required this.metodo});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    switch (metodo) {
      case 'TOQUE_MAPA':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'MIXTO':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        metodo,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
