import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../bloc/geo_editor_state.dart';

class GeoEditorMetricsBar extends StatelessWidget {
  final GeoEditorState state;

  const GeoEditorMetricsBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
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
